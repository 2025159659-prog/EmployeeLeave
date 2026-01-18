package util;

import java.sql.Connection;
import java.sql.DriverManager;

public class DatabaseConnection {

    private static final String DB_URL =
        System.getenv("JDBC_DATABASE_URL");

    static {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("PostgreSQL Driver not found", e);
        }
    }

    public static Connection getConnection() throws Exception {
        if (DB_URL == null || DB_URL.isEmpty()) {
            throw new RuntimeException("JDBC_DATABASE_URL not set");
        }
        return DriverManager.getConnection(DB_URL);
    }
}
