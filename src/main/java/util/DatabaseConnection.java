package util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {

    private static final String DATABASE_URL = System.getenv("DATABASE_URL");

    static {
        try {
            Class.forName("org.postgresql.Driver");
            System.out.println(">>> PostgreSQL Driver LOADED <<<");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("PostgreSQL Driver not found", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        if (DATABASE_URL == null || DATABASE_URL.isBlank()) {
            throw new RuntimeException("DATABASE_URL environment variable NOT SET");
        }

        System.out.println(">>> CONNECTING TO DATABASE <<<");
        System.out.println(">>> DATABASE_URL = " + DATABASE_URL);

        Connection con = DriverManager.getConnection(DATABASE_URL);

        System.out.println(">>> DATABASE CONNECTION SUCCESS <<<");
        return con;
    }
}
