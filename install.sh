#!/data/data/com.termux/files/usr/bin/bash
# Script para Termux - Instalador de clarox con detección de arquitectura
# Internet Bug Móvil DO - Desarrollador: Near365
# Telegram: @Near365

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# URLs del script Python según arquitectura
URL_ARM64="https://raw.githubusercontent.com/IntelectoDev/ElementManager/master/clarox_ARM64.py"
URL_ARM32="https://raw.githubusercontent.com/IntelectoDev/ElementManager/master/clarox_ARM32.py"

# Directorio de instalación
DEST="$PREFIX/bin/clarox"
PYTHON_SCRIPT="$PREFIX/share/clarox/clarox.py"
TEMP_FILE="$HOME/clarox_temp.py"

# Función para mostrar header
show_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║           INSTALADOR CLAROX - TERMUX                 ║${RESET}"
    echo -e "${CYAN}║              Internet Bug Móvil DO                   ║${RESET}"
    echo -e "${CYAN}║           Desarrollador: ${YELLOW}Near365${CYAN}                   ║${RESET}"
    echo -e "${CYAN}║             Telegram: @Near365                       ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# Función para logging
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[${timestamp}] [INFO] ${message}${RESET}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[${timestamp}] [✓] ${message}${RESET}"
            ;;
        "WARNING")
            echo -e "${YELLOW}[${timestamp}] [⚠] ${message}${RESET}"
            ;;
        "ERROR")
            echo -e "${RED}[${timestamp}] [✗] ${message}${RESET}"
            ;;
    esac
}

# Función para verificar conexión a internet
check_internet() {
    log "INFO" "Verificando conexión a internet..."
    if curl -s --max-time 10 -I https://www.google.com > /dev/null 2>&1; then
        log "SUCCESS" "Conexión a internet verificada"
        return 0
    else
        log "ERROR" "No hay conexión a internet"
        return 1
    fi
}

# Función para verificar si estamos en Termux
check_termux() {
    if [ -z "$PREFIX" ] || [ ! -d "$PREFIX" ]; then
        log "ERROR" "Este script debe ejecutarse en Termux"
        echo -e "${RED}Por favor instala Termux desde F-Droid o Google Play Store${RESET}"
        exit 1
    fi
    log "SUCCESS" "Entorno Termux verificado"
}

# Función para detectar arquitectura
detect_architecture() {
    ARCH=$(uname -m)
    log "INFO" "Detectando arquitectura del sistema..."
    log "INFO" "Arquitectura detectada: $ARCH"
    
    case "$ARCH" in
        "aarch64"|"arm64")
            log "INFO" "Sistema ARM64 detectado"
            URL="$URL_ARM64"
            ARCH_NAME="ARM64"
            ;;
        "armv7l"|"armv8l"|"armeabi")
            log "INFO" "Sistema ARM32 detectado"
            URL="$URL_ARM32"
            ARCH_NAME="ARM32"
            ;;
        *)
            log "ERROR" "Arquitectura no compatible: $ARCH"
            echo -e "${RED}Arquitecturas soportadas: ARM64, ARM32${RESET}"
            exit 1
            ;;
    esac
}

# Función para actualizar repositorios
update_repositories() {
    log "INFO" "Actualizando repositorios de Termux..."
    if pkg update -y; then
        log "SUCCESS" "Repositorios actualizados correctamente"
    else
        log "WARNING" "Error al actualizar repositorios, continuando..."
    fi
}

# Función para instalar dependencias
install_dependencies() {
    log "INFO" "Instalando dependencias necesarias..."
    
    # Lista de paquetes necesarios
    local packages=(
        "wget"
        "python"
        "python-pip"
        "libffi"
        "openssl"
        "libcrypt"
        "proot"
    )
    
    for package in "${packages[@]}"; do
        log "INFO" "Instalando $package..."
        if pkg install -y "$package"; then
            log "SUCCESS" "$package instalado correctamente"
        else
            log "WARNING" "Error al instalar $package, continuando..."
        fi
    done
    
    # Instalar dependencias Python específicas (solo las esenciales)
    log "INFO" "Instalando dependencias Python esenciales..."
    if pip install --upgrade requests urllib3; then
        log "SUCCESS" "Dependencias Python instaladas"
    else
        log "WARNING" "Error al instalar dependencias Python, continuando..."
    fi
}

# Función para descargar el script Python
download_python_script() {
    log "INFO" "Descargando clarox.py ($ARCH_NAME)..."
    log "INFO" "URL: $URL"
    
    # Usar directorio home en lugar de /tmp
    log "INFO" "Usando directorio temporal: $HOME"
    
    # Limpiar archivo temporal si existe
    [ -f "$TEMP_FILE" ] && rm -f "$TEMP_FILE"
    
    # Descargar con wget con opciones robustas
    if wget \
        --no-check-certificate \
        --retry-connrefused \
        --waitretry=2 \
        --timeout=120 \
        --tries=3 \
        --progress=bar \
        --user-agent="Mozilla/5.0 (Linux; Android 10; Mobile)" \
        -O "$TEMP_FILE" \
        "$URL"; then
        
        log "SUCCESS" "Descarga completada"
        return 0
    else
        log "WARNING" "Error con wget, intentando con curl..."
        # Fallback a curl si wget falla
        if curl -k -L \
            --retry 3 \
            --retry-delay 2 \
            --max-time 120 \
            --progress-bar \
            --user-agent "Mozilla/5.0 (Linux; Android 10; Mobile)" \
            -o "$TEMP_FILE" \
            "$URL"; then
            
            log "SUCCESS" "Descarga completada con curl"
            return 0
        else
            log "ERROR" "Error al descargar el archivo desde $URL"
            return 1
        fi
    fi
}

# Función para verificar el archivo descargado
verify_download() {
    log "INFO" "Verificando archivo descargado..."
    
    if [ ! -f "$TEMP_FILE" ]; then
        log "ERROR" "Archivo temporal no encontrado en $TEMP_FILE"
        return 1
    fi
    
    # Verificar que el archivo no está vacío
    if [ ! -s "$TEMP_FILE" ]; then
        log "ERROR" "El archivo descargado está vacío"
        return 1
    fi
    
    # Verificar tamaño mínimo del archivo
    local file_size=$(stat -c%s "$TEMP_FILE" 2>/dev/null || wc -c < "$TEMP_FILE")
    if [ "$file_size" -lt 100 ]; then
        log "ERROR" "El archivo descargado es demasiado pequeño ($file_size bytes)"
        log "INFO" "Contenido del archivo:"
        head -n 5 "$TEMP_FILE"
        return 1
    fi
    
    # Verificar que es un archivo Python válido o contiene código Python
    if head -n 1 "$TEMP_FILE" | grep -q "python\|#!/usr/bin/env python"; then
        log "SUCCESS" "Archivo Python verificado correctamente (shebang detectado)"
        return 0
    elif grep -q "import\|def\|class\|print(" "$TEMP_FILE"; then
        log "SUCCESS" "Archivo Python verificado correctamente (código Python detectado)"
        return 0
    elif file "$TEMP_FILE" 2>/dev/null | grep -q "Python script"; then
        log "SUCCESS" "Archivo Python verificado correctamente (file command)"
        return 0
    else
        log "WARNING" "No se pudo verificar que sea un archivo Python válido"
        log "INFO" "Primeras líneas del archivo:"
        head -n 3 "$TEMP_FILE"
        log "INFO" "Continuando con la instalación..."
        return 0
    fi
}

# Función para instalar el script Python
install_python_script() {
    log "INFO" "Instalando clarox.py..."
    
    # Crear directorio para el script Python
    local script_dir="$(dirname "$PYTHON_SCRIPT")"
    mkdir -p "$script_dir"
    
    # Crear backup si existe versión anterior
    if [ -f "$PYTHON_SCRIPT" ]; then
        log "INFO" "Creando backup de versión anterior..."
        cp "$PYTHON_SCRIPT" "$PYTHON_SCRIPT.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Mover el archivo temporal al destino final
    if mv "$TEMP_FILE" "$PYTHON_SCRIPT"; then
        log "SUCCESS" "Script Python movido correctamente"
    else
        log "ERROR" "Error al mover el archivo a $PYTHON_SCRIPT"
        return 1
    fi
    
    # Hacer ejecutable
    if chmod +x "$PYTHON_SCRIPT"; then
        log "SUCCESS" "Permisos de ejecución aplicados al script Python"
    else
        log "ERROR" "Error al aplicar permisos de ejecución"
        return 1
    fi
    
    # Crear wrapper ejecutable
    create_wrapper_script || return 1
    
    return 0
}

# Función para crear el script wrapper
create_wrapper_script() {
    log "INFO" "Creando script wrapper ejecutable..."
    
    # Crear backup si existe versión anterior
    if [ -f "$DEST" ]; then
        log "INFO" "Creando backup de wrapper anterior..."
        cp "$DEST" "$DEST.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Crear el script wrapper
    cat > "$DEST" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Wrapper script para clarox.py
# Auto-generado por el instalador

PYTHON_SCRIPT="$PREFIX/share/clarox/clarox.py"

# Verificar que el script Python existe
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Script Python no encontrado en $PYTHON_SCRIPT"
    echo "Por favor reinstala clarox ejecutando: bash install.sh"
    exit 1
fi

# Verificar que Python está disponible
if ! command -v python >/dev/null 2>&1; then
    echo "Error: Python no está instalado"
    echo "Por favor instala Python con: pkg install python"
    exit 1
fi

# Ejecutar el script Python con todos los argumentos
exec python "$PYTHON_SCRIPT" "$@"
EOF

    # Hacer ejecutable el wrapper
    if chmod +x "$DEST"; then
        log "SUCCESS" "Wrapper script creado y configurado"
        return 0
    else
        log "ERROR" "Error al aplicar permisos de ejecución al wrapper"
        return 1
    fi
}

# Función para crear directorio de configuración
create_config_dir() {
    local config_dir="$HOME/.bugx_config"
    log "INFO" "Creando directorio de configuración..."
    
    if mkdir -p "$config_dir"; then
        chmod 700 "$config_dir"
        log "SUCCESS" "Directorio de configuración creado: $config_dir"
    else
        log "WARNING" "Error al crear directorio de configuración"
    fi
}

# Función para verificar instalación
verify_installation() {
    log "INFO" "Verificando instalación..."
    
    # Verificar que el wrapper existe y es ejecutable
    if [ ! -x "$DEST" ]; then
        log "ERROR" "El wrapper no es ejecutable"
        return 1
    fi
    
    # Verificar que el script Python existe
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        log "ERROR" "El script Python no existe"
        return 1
    fi
    
    # Verificar que Python está disponible
    if ! command -v python >/dev/null 2>&1; then
        log "ERROR" "Python no está disponible"
        return 1
    fi
    
    log "SUCCESS" "Instalación verificada correctamente"
    return 0
}

# Función para mostrar información post-instalación
show_post_install_info() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║                 INSTALACIÓN COMPLETADA               ║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${CYAN}📱 INSTRUCCIONES DE USO:${RESET}"
    echo -e "${WHITE}1. Para ejecutar clarox, escribe: ${GREEN}clarox${RESET}"
    echo -e "${WHITE}2. El programa te mostrará tu HWID único${RESET}"
    echo -e "${WHITE}3. Contacta a un suplidor para activar tu HWID${RESET}"
    echo -e "${WHITE}4. Una vez activado, el programa funcionará automáticamente${RESET}"
    echo ""
    echo -e "${CYAN}🔧 COMANDOS ÚTILES:${RESET}"
    echo -e "${WHITE}• Ejecutar: ${GREEN}clarox${RESET}"
    echo -e "${WHITE}• Ejecutar directamente: ${GREEN}python $PYTHON_SCRIPT${RESET}"
    echo -e "${WHITE}• Detener: ${YELLOW}Ctrl + C${RESET}"
    echo -e "${WHITE}• Reinstalar: ${YELLOW}bash install.sh${RESET}"
    echo ""
    echo -e "${CYAN}📂 UBICACIÓN DE ARCHIVOS:${RESET}"
    echo -e "${WHITE}• Ejecutable: ${GREEN}$DEST${RESET}"
    echo -e "${WHITE}• Script Python: ${GREEN}$PYTHON_SCRIPT${RESET}"
    echo -e "${WHITE}• Configuración: ${GREEN}$HOME/.bugx_config${RESET}"
    echo ""
    echo -e "${CYAN}📞 SOPORTE:${RESET}"
    echo -e "${WHITE}• Telegram: ${GREEN}@Near365${RESET}"
    echo -e "${WHITE}• Para problemas o activación de HWID${RESET}"
    echo ""
    echo -e "${CYAN}⚠️  NOTAS IMPORTANTES:${RESET}"
    echo -e "${WHITE}• Necesitas conexión a internet para la activación inicial${RESET}"
    echo -e "${WHITE}• El programa mantiene la conexión automáticamente${RESET}"
    echo -e "${WHITE}• Solo funciona en dispositivos móviles con Termux${RESET}"
    echo -e "${WHITE}• El script Python se ejecuta automáticamente${RESET}"
    echo ""
}

# Función para limpiar archivos temporales
cleanup() {
    log "INFO" "Limpiando archivos temporales..."
    [ -f "$TEMP_FILE" ] && rm -f "$TEMP_FILE"
    log "SUCCESS" "Limpieza completada"
}

# Función principal
main() {
    # Mostrar header
    show_header
    
    # Verificaciones iniciales
    check_termux
    check_internet || {
        log "ERROR" "Se requiere conexión a internet para la instalación"
        exit 1
    }
    
    # Detectar arquitectura
    detect_architecture
    
    # Actualizar repositorios
    update_repositories
    
    # Instalar dependencias
    install_dependencies
    
    # Descargar script Python
    download_python_script || {
        log "ERROR" "Fallo en la descarga del script Python"
        cleanup
        exit 1
    }
    
    # Verificar descarga
    verify_download || {
        log "ERROR" "Fallo en la verificación del archivo"
        cleanup
        exit 1
    }
    
    # Instalar script Python
    install_python_script || {
        log "ERROR" "Fallo en la instalación del script Python"
        cleanup
        exit 1
    }
    
    # Verificar instalación
    verify_installation || {
        log "ERROR" "Fallo en la verificación de la instalación"
        cleanup
        exit 1
    }
    
    # Crear directorio de configuración
    create_config_dir
    
    # Limpiar archivos temporales
    cleanup
    
    # Mostrar información post-instalación
    show_post_install_info
    
    log "SUCCESS" "¡Instalación completada exitosamente!"
    
    # Auto-eliminar el script si fue ejecutado directamente
    if [ "$0" = "./install.sh" ] || [ "$0" = "bash install.sh" ]; then
        log "INFO" "Eliminando script de instalación..."
        rm -f "$0" 2>/dev/null || true
    fi
}

# Manejo de señales para limpieza
trap cleanup EXIT INT TERM

# Ejecutar función principal
main "$@"
