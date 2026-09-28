package edu.ucentral.vinni.dto;

public class AnalisisRequest {
    private String imagenBase64;
    private String nombreArchivo;

    // Constructor vacío obligatorio para Jackson
    public AnalisisRequest() {
    }

    public AnalisisRequest(String imagenBase64, String nombreArchivo) {
        this.imagenBase64 = imagenBase64;
        this.nombreArchivo = nombreArchivo;
    }

    public String getImagenBase64() { 
        return imagenBase64; 
    }
    
    public void setImagenBase64(String imagenBase64) { 
        this.imagenBase64 = imagenBase64; 
    }
    
    public String getNombreArchivo() { 
        return nombreArchivo; 
    }
    
    public void setNombreArchivo(String nombreArchivo) { 
        this.nombreArchivo = nombreArchivo; 
    }
}