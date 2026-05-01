//! No-op output recovery compatibility layer.
//!
//! Enterprise builds must not persist command output. Command filters still call
//! these helpers from existing execution paths, but the helpers intentionally
//! never write files or return filesystem hints.

use std::path::PathBuf;

/// Retained only so existing config files deserialize without data collection.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq, Default)]
#[serde(rename_all = "lowercase")]
pub enum TeeMode {
    Failures,
    Always,
    #[default]
    Never,
}

/// Compatibility config for disabled raw-output recovery.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct TeeConfig {
    pub enabled: bool,
    pub mode: TeeMode,
    pub max_files: usize,
    pub max_file_size: usize,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub directory: Option<PathBuf>,
}

impl Default for TeeConfig {
    fn default() -> Self {
        Self {
            enabled: false,
            mode: TeeMode::Never,
            max_files: 0,
            max_file_size: 0,
            directory: None,
        }
    }
}

/// Raw-output persistence is disabled for enterprise builds.
pub fn tee_and_hint(_raw: &str, _command_slug: &str, _exit_code: i32) -> Option<String> {
    None
}

/// Raw-output persistence is disabled for enterprise builds.
pub fn force_tee_hint(_raw: &str, _command_slug: &str) -> Option<String> {
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_tee_config_is_disabled() {
        let config = TeeConfig::default();
        assert!(!config.enabled);
        assert_eq!(config.mode, TeeMode::Never);
    }

    #[test]
    fn tee_helpers_do_not_persist_or_return_hints() {
        assert!(tee_and_hint("secret output", "cmd", 1).is_none());
        assert!(force_tee_hint("secret output", "cmd").is_none());
    }
}
