from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.monitoring import setup_sentry
from app.modules.identity.router import router as identity_router
from app.modules.loyalty.router import router as loyalty_router
from app.modules.qr.router import router as qr_router


def create_app() -> FastAPI:
    settings = get_settings()
    setup_sentry(settings)
    expose_api_docs = settings.app_env.lower() != "production"
    app = FastAPI(
        title="Zomia API",
        version="0.1.0",
        docs_url="/docs" if expose_api_docs else None,
        redoc_url="/redoc" if expose_api_docs else None,
        openapi_url="/openapi.json" if expose_api_docs else None,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/health", tags=["health"])
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.head("/health", tags=["health"])
    def health_head() -> Response:
        return Response(status_code=200)

    app.include_router(identity_router, prefix="/api/v1")
    app.include_router(loyalty_router, prefix="/api/v1")
    app.include_router(qr_router, prefix="/api/v1")
    return app


app = create_app()
