package com.tramdoc;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class CheckDemoData {
    public static void main(String[] args) {
        String url = "jdbc:mysql://localhost:3306/tram_doc_db?useSSL=false&allowPublicKeyRetrieval=true";
        String user = "root";
        String password = "giang2005";
        
        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement()) {
            
            System.out.println("--- USERS IN DB ---");
            ResultSet rs = stmt.executeQuery("SELECT id, email, password FROM users");
            while (rs.next()) {
                System.out.println("ID: " + rs.getLong("id") + ", Email: " + rs.getString("email") + ", Hash: " + rs.getString("password"));
            }
            
            System.out.println("\n--- GENERATING NEW HASH FOR 'password123' ---");
            BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
            String freshHash = encoder.encode("password123");
            System.out.println("Fresh hash: " + freshHash);
            
            System.out.println("\n--- UPDATING DB WITH FRESH HASH ---");
            int rows = stmt.executeUpdate("UPDATE users SET password = '" + freshHash + "' WHERE email LIKE 'reader%'");
            System.out.println("Updated " + rows + " rows with fresh hash.");
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
