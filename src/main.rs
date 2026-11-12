use axum::{Router, routing::get};
use tokio::net::TcpListener;

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let app = Router::new().route(
        "/",
        get(|| async {
            println!("Hello, world! requested");
            "Hello, world!\n"
        }),
    );

    let listener = TcpListener::bind("[::]:8080").await?;
    println!("Listening on {}", listener.local_addr()?);
    axum::serve(listener, app).await
}
