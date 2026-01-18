package util;

import java.net.URI;
import java.sql.Connection;
import java.sql.DriverManager;

public class DatabaseConnection {

    static {
        try {
            Class.forName("org.postgresql.Driver");
            System.out.println(">>> PostgreSQL Driver LOADED <<<");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("PostgreSQL Driver not found", e);
        }
    }

    public static Connection getConnection() throws Exception {

        String databaseUrl = System.getenv("DATABASE_URL");

        if (databaseUrl == null || databaseUrl.isBlank()) {
            throw new RuntimeException("DATABASE_URL not set");
        }

        System.out.println(">>> RAW DATABASE_URL = " + databaseUrl);

        URI uri = new URI(databaseUrl);

        String username = uri.getUserInfo().split(":")[0];
        String password = uri.getUserInfo().split(":")[1];

        String jdbcUrl = "jdbc:postgresql://" +
                uri.getHost() + ":" +
                uri.getPort() +
                uri.getPath() +
                "?sslmode=require";

        System.out.println(">>> JDBC URL = " + jdbcUrl);
        System.out.println(">>> DB USER = " + username);

        Connection con = DriverManager.getConnection(jdbcUrl, username, password);

        System.out.println(">>> DATABASE CONNECTION SUCCESS <<<");

        return con;
    }
}
