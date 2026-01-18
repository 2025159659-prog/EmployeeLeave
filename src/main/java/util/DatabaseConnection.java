import java.sql.Connection;
import java.sql.DriverManager;
import java.net.URI;

public class DatabaseConnection {

    public static Connection getConnection() throws Exception {

        String dbUrl = System.getenv("DATABASE_URL");
        if (dbUrl == null) {
            throw new RuntimeException("DATABASE_URL is not set");
        }

        URI uri = new URI(dbUrl);

        String[] userInfo = uri.getUserInfo().split(":");
        String username = userInfo[0];
        String password = userInfo[1];

        String jdbcUrl = "jdbc:postgresql://" +
                uri.getHost() + ":" +
                uri.getPort() +
                uri.getPath() +
                "?sslmode=require";

        Class.forName("org.postgresql.Driver");
        return DriverManager.getConnection(jdbcUrl, username, password);
    }
}
