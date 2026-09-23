package edu.ucentral.vinni.security;

public final class AuthorizationTokens {

    private AuthorizationTokens() {
    }

    public static String extraer(String authorization) {
        if (authorization == null || authorization.isBlank()) {
            return null;
        }

        String token = authorization.trim();
        if (token.regionMatches(true, 0, "Bearer ", 0, 7)) {
            token = token.substring(7).trim();
        }

        return token.isEmpty() ? null : token;
    }
}
