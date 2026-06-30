import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class CheckDB {
    public static void main(String[] args) {
        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/tram_doc_db?serverTimezone=Asia/Ho_Chi_Minh", 
                "root", "Giang2005"
            );
            Statement stmt = conn.createStatement();
            
            System.out.println("--- USERS ---");
            ResultSet rs = stmt.executeQuery("SELECT id, email, full_name, auth_provider FROM users");
            while (rs.next()) {
                System.out.println("ID=" + rs.getInt("id") + ", Email=" + rs.getString("email") + 
                    ", Name=" + rs.getString("full_name") + ", Provider=" + rs.getString("auth_provider"));
            }
            
            System.out.println("\n--- BOOKS in USER_BOOKS ---");
            ResultSet rs2 = stmt.executeQuery("SELECT count(*) as count FROM user_books");
            if (rs2.next()) {
                System.out.println("Total User Books: " + rs2.getInt("count"));
            }
            
            stmt.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
