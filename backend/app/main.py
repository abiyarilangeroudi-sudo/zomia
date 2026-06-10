from fastapi import FastAPI

from app.modules.identity.router import router as identity_router


def create_app() -> FastAPI:
    app = FastAPI(title="Zomia API", version="0.1.0")

    @app.get("/health", tags=["health"])
    def health() -> dict[str, str]:
        return {"status": "ok"}

    app.include_router(identity_router, prefix="/api/v1")
    return app


app = create_app()

