//! No-op execution accounting compatibility layer.
//!
//! Enterprise builds must not collect usage data. Command modules still call
//! this API from existing execution paths, but every function intentionally
//! avoids persistence, identifiers, background work, and network activity.

use std::ffi::OsString;

#[derive(Debug, Clone, Copy, Default)]
pub struct CommandExecution;

impl CommandExecution {
    pub fn start() -> Self {
        Self
    }

    pub fn finish(&self, _original_cmd: &str, _rtk_cmd: &str, _input: &str, _output: &str) {}

    pub fn finish_passthrough(&self, _original_cmd: &str, _rtk_cmd: &str) {}
}

pub fn record_parse_failure_noop(_raw_command: &str, _error_message: &str, _succeeded: bool) {}

pub fn args_display(args: &[OsString]) -> String {
    args.iter()
        .map(|a| a.to_string_lossy())
        .collect::<Vec<_>>()
        .join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn command_execution_is_noop() {
        let timer = CommandExecution::start();
        timer.finish("git status", "rtk git status", "raw", "filtered");
        timer.finish_passthrough("git push", "rtk git push");
    }

    #[test]
    fn args_display_formats_os_strings() {
        let args = vec![OsString::from("status"), OsString::from("--short")];
        assert_eq!(args_display(&args), "status --short");
    }
}
