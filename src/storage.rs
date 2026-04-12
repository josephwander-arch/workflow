//! Shared JSON file storage layer with atomic writes
//! All workflow data lives in C:\CPC\workflows\ as JSON files.

use anyhow::{Context, Result};
use serde::de::DeserializeOwned;
use serde::Serialize;
use std::path::PathBuf;

pub struct JsonStore {
    base_dir: PathBuf,
}

impl JsonStore {
    pub fn new() -> Self {
        let base_dir = PathBuf::from(r"C:\CPC\workflows");
        Self { base_dir }
    }

    pub fn ensure_dir(&self) -> Result<()> {
        std::fs::create_dir_all(&self.base_dir)
            .with_context(|| format!("Failed to create {}", self.base_dir.display()))
    }

    pub fn load<T: DeserializeOwned>(&self, filename: &str) -> Result<T> {
        let path = self.base_dir.join(filename);
        let data = std::fs::read_to_string(&path)
            .with_context(|| format!("Failed to read {}", path.display()))?;
        serde_json::from_str(&data)
            .with_context(|| format!("Failed to parse {}", path.display()))
    }

    pub fn load_or_default<T: DeserializeOwned + Default>(&self, filename: &str) -> T {
        self.load(filename).unwrap_or_default()
    }

    pub fn save<T: Serialize>(&self, filename: &str, data: &T) -> Result<()> {
        self.ensure_dir()?;
        let path = self.base_dir.join(filename);
        let tmp = self.base_dir.join(format!("{}.tmp", filename));
        let json = serde_json::to_string_pretty(data)
            .context("Failed to serialize")?;
        std::fs::write(&tmp, &json)
            .with_context(|| format!("Failed to write {}", tmp.display()))?;
        std::fs::rename(&tmp, &path)
            .with_context(|| format!("Failed to rename {} -> {}", tmp.display(), path.display()))?;
        Ok(())
    }

    pub fn path(&self, filename: &str) -> PathBuf {
        self.base_dir.join(filename)
    }
}
