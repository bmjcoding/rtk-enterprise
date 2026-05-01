use anyhow::{bail, Result};
use std::process::Command;

const CHILD_MARKER_ENV: &str = "RTK_ENTERPRISE_CHILD_PROCESS";
const PARENT_POLICY_ENV: &str = "RTK_ENTERPRISE_PARENT_EGRESS_POLICY";
const DIRECT_RTK_EGRESS_POLICY: &str = "deny-direct-rtk-egress";
const UNSUPPORTED_ALLOW_ENV: &str = "RTK_ENTERPRISE_ALLOW_DIRECT_EGRESS";

pub fn enforce_startup_policy() -> Result<()> {
    if std::env::var_os(UNSUPPORTED_ALLOW_ENV).is_some() {
        bail!(
            "{} is not supported. RTK-owned direct outbound connections are denied; run network-capable tools as child commands and govern those tools separately.",
            UNSUPPORTED_ALLOW_ENV
        );
    }

    Ok(())
}

pub fn mark_child_command(cmd: &mut Command) {
    cmd.env(CHILD_MARKER_ENV, "1");
    cmd.env(PARENT_POLICY_ENV, DIRECT_RTK_EGRESS_POLICY);
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::OsStr;

    #[test]
    fn child_commands_are_marked_for_policy_separation() {
        let mut cmd = Command::new("tool");
        mark_child_command(&mut cmd);

        let envs: Vec<_> = cmd.get_envs().collect();
        assert!(envs.iter().any(|(key, value)| {
            *key == OsStr::new(CHILD_MARKER_ENV) && value.is_some_and(|v| v == OsStr::new("1"))
        }));
        assert!(envs.iter().any(|(key, value)| {
            *key == OsStr::new(PARENT_POLICY_ENV)
                && value.is_some_and(|v| v == OsStr::new(DIRECT_RTK_EGRESS_POLICY))
        }));
    }
}
