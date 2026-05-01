use std::collections::HashSet;
use std::fs;
use std::path::Path;

fn main() {
    #[cfg(windows)]
    {
        // Clap + the full command graph can exceed the default 1 MiB Windows
        // main-thread stack during process startup. Reserve a larger stack for
        // the CLI binary so `rtk.exe --version`, `--help`, and hook entry
        // points start reliably without requiring ad-hoc RUSTFLAGS.
        println!("cargo:rustc-link-arg=/STACK:8388608");
    }

    enforce_enterprise_egress_build_guard();

    let filters_dir = Path::new("src/filters");
    let out_dir = std::env::var("OUT_DIR").expect("OUT_DIR must be set by Cargo");
    let dest = Path::new(&out_dir).join("builtin_filters.toml");

    // Rebuild when any file in src/filters/ changes
    println!("cargo:rerun-if-changed=src/filters");

    let mut files: Vec<_> = fs::read_dir(filters_dir)
        .expect("src/filters/ directory must exist")
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().is_some_and(|ext| ext == "toml"))
        .collect();

    // Sort alphabetically for deterministic filter ordering
    files.sort_by_key(|e| e.file_name());

    let mut combined = String::from("schema_version = 1\n\n");

    for entry in &files {
        let content = fs::read_to_string(entry.path())
            .unwrap_or_else(|e| panic!("Failed to read {:?}: {}", entry.path(), e));
        combined.push_str(&format!(
            "# --- {} ---\n",
            entry.file_name().to_string_lossy()
        ));
        combined.push_str(&content);
        combined.push_str("\n\n");
    }

    // Validate: parse the combined TOML to catch errors at build time
    let parsed: toml::Value = combined.parse().unwrap_or_else(|e| {
        panic!(
            "TOML validation failed for combined filters:\n{}\n\nCheck src/filters/*.toml files",
            e
        )
    });

    // Detect duplicate filter names across files
    if let Some(filters) = parsed.get("filters").and_then(|f| f.as_table()) {
        let mut seen: HashSet<String> = HashSet::new();
        for key in filters.keys() {
            if !seen.insert(key.clone()) {
                panic!(
                    "Duplicate filter name '{}' found across src/filters/*.toml files",
                    key
                );
            }
        }
    }

    fs::write(&dest, combined).expect("Failed to write combined builtin_filters.toml");
}

const FORBIDDEN_RUNTIME_PATTERNS: &[(&str, &str)] = &[
    ("std::net::", "standard library network namespace"),
    ("use std::net", "standard library network import"),
    ("TcpStream", "TCP client stream"),
    ("TcpListener", "TCP listener"),
    ("UdpSocket", "UDP socket"),
    ("ToSocketAddrs", "address resolution"),
    ("reqwest::", "HTTP client API"),
    ("ureq::", "HTTP client API"),
    ("hyper::", "HTTP client API"),
    ("isahc::", "HTTP client API"),
    ("surf::", "HTTP client API"),
    ("rusqlite::", "SQLite API"),
    ("libsqlite3_sys", "SQLite FFI API"),
    ("Connection::open(", "database open call"),
];

const FORBIDDEN_DEPENDENCY_NAMES: &[&str] = &[
    "reqwest",
    "ureq",
    "hyper",
    "h2",
    "http-body",
    "isahc",
    "surf",
    "native-tls",
    "rustls",
    "openssl",
    "webpki-roots",
    "tokio-rustls",
    "hyper-rustls",
    "hyper-tls",
    "rusqlite",
    "libsqlite3-sys",
];

fn enforce_enterprise_egress_build_guard() {
    println!("cargo:rerun-if-changed=src");
    println!("cargo:rerun-if-changed=Cargo.toml");
    println!("cargo:rerun-if-changed=Cargo.lock");

    scan_runtime_sources(Path::new("src"));
    scan_lockfile_for_forbidden_dependencies(Path::new("Cargo.lock"));
}

fn scan_runtime_sources(path: &Path) {
    let entries = fs::read_dir(path)
        .unwrap_or_else(|e| panic!("Failed to read source path {:?}: {}", path, e));

    for entry in entries.filter_map(|e| e.ok()) {
        let path = entry.path();
        if path.is_dir() {
            scan_runtime_sources(&path);
            continue;
        }

        if path.extension().is_some_and(|ext| ext == "rs") {
            println!("cargo:rerun-if-changed={}", path.display());
            let content = fs::read_to_string(&path)
                .unwrap_or_else(|e| panic!("Failed to read {:?}: {}", path, e));
            for (pattern, label) in FORBIDDEN_RUNTIME_PATTERNS {
                if content.contains(pattern) {
                    panic!(
                        "Enterprise direct-egress build guard: forbidden {} pattern '{}' found in {}",
                        label,
                        pattern,
                        path.display()
                    );
                }
            }
        }
    }
}

fn scan_lockfile_for_forbidden_dependencies(path: &Path) {
    if !path.exists() {
        return;
    }

    let content =
        fs::read_to_string(path).unwrap_or_else(|e| panic!("Failed to read {:?}: {}", path, e));
    let parsed: toml::Value = content
        .parse()
        .unwrap_or_else(|e| panic!("Failed to parse {:?}: {}", path, e));
    let Some(packages) = parsed.get("package").and_then(|v| v.as_array()) else {
        return;
    };

    for package in packages {
        let Some(name) = package.get("name").and_then(|v| v.as_str()) else {
            continue;
        };

        if FORBIDDEN_DEPENDENCY_NAMES.contains(&name) {
            panic!(
                "Enterprise direct-egress build guard: forbidden dependency '{}' found in {}",
                name,
                path.display()
            );
        }
    }
}
