use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    pub database_url: String,
    pub jwt_secret: String,
    pub server_port: u16,
}

impl Config {
    pub fn from_env() -> Result<Self, config::ConfigError> {
        dotenvy::dotenv().ok();
        
        let config = config::Config::builder()
            .add_source(config::Environment::default())
            .set_default("server_port", 8080)?
            .set_default("jwt_secret", "your-secret-key-change-in-production")?
            .set_default("database_url", "postgresql://localhost/zipproperty")?
            .build()?;

        config.try_deserialize()
    }
}
