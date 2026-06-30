package com.tramdoc;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class LoadDemoData {
    public static void main(String[] args) {
        String url = "jdbc:mysql://localhost:3306/tram_doc_db?useSSL=false&allowPublicKeyRetrieval=true";
        String user = "root";
        String password = "giang2005";
        
        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement()) {
            
            System.out.println("Reading demo_data.sql...");
            String sql = new String(Files.readAllBytes(Paths.get("d:/Reading_Station/demo_data.sql")));
            
            // Very simple script runner: split by ';'
            String[] commands = sql.split(";");
            for (String command : commands) {
                if (command.trim().isEmpty()) continue;
                try {
                    stmt.execute(command);
                    System.out.println("Executed successfully.");
                } catch (Exception ex) {
                    System.err.println("Error executing command: " + ex.getMessage());
                }
            }
            System.out.println("Demo data import finished.");
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
