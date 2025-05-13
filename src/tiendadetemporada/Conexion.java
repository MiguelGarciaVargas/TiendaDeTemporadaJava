/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package tiendadetemporada;
import java.sql.Connection; 
import java.sql.DriverManager; 
import javax.swing.JOptionPane;

/**
 *
 * @author MONSE
 */
public class Conexion {
    private static final String URL = "jdbc:postgresql://localhost:5432/TiendaDeTemporada"; 
    private static final String USUARIO = "postgres"; 
    private static final String CONTRASENA = "postgres"; 
    
    public static Connection conectar() { 
        Connection conexion = null; 
        try { 
            Class.forName("org.postgresql.Driver"); 
            conexion = DriverManager.getConnection(URL, USUARIO, CONTRASENA); 
            //JOptionPane.showMessageDialog(null, "Conexión exitosa a PostgreSQL", "Éxito", JOptionPane.INFORMATION_MESSAGE); 
        } catch (Exception e) { 
            JOptionPane.showMessageDialog(null, "Error en la conexión", "Error de conexion", JOptionPane.ERROR_MESSAGE); 
        } 
        return conexion; 
    }
    
     public static void main(String[] args) { 
        Connection conexion = conectar(); 
        if(conexion != null){ 
            System.out.println("Conexion Exitosa"); 
        } 
        else { 
            System.out.println("Conexion Fallida"); 
        } 
    }
}
