from pathlib import Path


SOURCE = Path(__file__).parent / "elastic-simulate-chat" / "index.ts"


def test_simulated_chat_function_is_jwt_gated_and_non_durable():
    text = SOURCE.read_text(encoding="utf-8")
    assert 'req.method !== "POST"' in text
    assert '"missing_bearer_token"' in text
    assert 'simulated: true' in text
    assert 'persistence: "not-written"' in text
    assert 'service_role' not in text


def test_simulated_chat_function_returns_a2a_correlation_shape():
    text = SOURCE.read_text(encoding="utf-8")
    for field in ("session_id", "task_id", "context_id", "cancel_state", "correlation"):
        assert field in text
