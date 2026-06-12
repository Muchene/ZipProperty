use sqlx::{migrate::MigrateDatabase, PgPool, Postgres};

pub async fn init_pool(database_url: &str) -> Result<PgPool, sqlx::Error> {
    // Create database if it doesn't exist
    if !Postgres::database_exists(database_url).await.unwrap_or(false) {
        Postgres::create_database(database_url).await?;
        tracing::info!("Database created");
    }

    let pool = PgPool::connect(database_url).await?;
    tracing::info!("Database connected");
    Ok(pool)
}

pub async fn run_migrations(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::migrate!("./migrations").run(pool).await?;
    tracing::info!("Migrations completed");
    Ok(())
}
