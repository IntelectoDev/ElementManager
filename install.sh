#!/data/data/com.termux/files/usr/bin/bash
# Script para Termux - Instalador de clarox con Python
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

# URLs del archivo Python
URL_PYTHON="https://raw.githubusercontent.com/IntelectoDev/ElementManager/master/clarox_enc.py"

# Directorios de instalación
DEST_DIR="$PREFIX/bin"
DEST_SCRIPT="$DEST_DIR/clarox.py"
DEST_WRAPPER="$DEST_DIR/clarox"
TEMP_FILE="/tmp/clarox_temp.py"

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

# Función para detectar arquitectura (para información solamente)
detect_architecture() {
    ARCH=$(uname -m)
    log "INFO" "Detectando arquitectura del sistema..."
    log "INFO" "Arquitectura detectada: $ARCH"
    
    case "$ARCH" in
        "aarch64"|"arm64")
            log "INFO" "Sistema ARM64 detectado"
            ARCH_NAME="ARM64"
            ;;
        "armv7l"|"armv8l"|"armeabi")
            log "INFO" "Sistema ARM32 detectado"
            ARCH_NAME="ARM32"
            ;;
        *)
            log "WARNING" "Arquitectura no estándar: $ARCH"
            ARCH_NAME="UNKNOWN"
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
        "curl"
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
    
    # Instalar dependencias Python específicas
    log "INFO" "Instalando dependencias Python..."
    local python_packages=(
        "cryptography"
        "requests"
        "urllib3"
        "certifi"
        "charset-normalizer"
        "idna"
        "cffi"
        "pycparser"
    )
    
    for py_package in "${python_packages[@]}"; do
        log "INFO" "Instalando $py_package..."
        if pip install --upgrade "$py_package"; then
            log "SUCCESS" "$py_package instalado correctamente"
        else
            log "WARNING" "Error al instalar $py_package"
        fi
    done
}

# Función para descargar el archivo Python
download_python_script() {
    log "INFO" "Descargando clarox.py..."
    log "INFO" "URL: $URL_PYTHON"
    
    # Crear directorio temporal si no existe
    mkdir -p "$(dirname "$TEMP_FILE")"
    
    # Descargar con curl con opciones robustas
    if curl -L \
        --retry 3 \
        --retry-delay 2 \
        --max-time 120 \
        --progress-bar \
        --user-agent "Mozilla/5.0 (Linux; Android 10; Mobile)" \
        -o "$TEMP_FILE" \
        "$URL_PYTHON"; then
        
        log "SUCCESS" "Descarga completada"
        return 0
    else
        log "ERROR" "Error al descargar el archivo desde $URL_PYTHON"
        return 1
    fi
}

# Función para verificar el archivo descargado
verify_download() {
    log "INFO" "Verificando archivo descargado..."
    
    if [ ! -f "$TEMP_FILE" ]; then
        log "ERROR" "Archivo temporal no encontrado"
        return 1
    fi
    
    # Verificar que el archivo no está vacío
    if [ ! -s "$TEMP_FILE" ]; then
        log "ERROR" "El archivo descargado está vacío"
        return 1
    fi
    
    # Verificar que es un archivo Python válido
    if head -n 1 "$TEMP_FILE" | grep -q "python\|#!/usr/bin/env python"; then
        log "SUCCESS" "Archivo Python verificado correctamente"
        return 0
    elif grep -q "import\|def\|class" "$TEMP_FILE"; then
        log "SUCCESS" "Archivo Python verificado correctamente"
        return 0
    else
        log "WARNING" "El archivo puede no ser un script Python válido, continuando..."
        return 0
    fi
}

# Función para instalar el script Python
install_python_script() {
    log "INFO" "Instalando clarox.py en $DEST_SCRIPT..."
    
    # Crear backup si existe versión anterior
    if [ -f "$DEST_SCRIPT" ]; then
        log "INFO" "Creando backup de versión anterior..."
        cp "$DEST_SCRIPT" "$DEST_SCRIPT.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Mover el archivo temporal al destino final
    if mv "$TEMP_FILE" "$DEST_SCRIPT"; then
        log "SUCCESS" "Archivo Python movido correctamente"
    else
        log "ERROR" "Error al mover el archivo a $DEST_SCRIPT"
        return 1
    fi
    
    # Hacer ejecutable
    if chmod +x "$DEST_SCRIPT"; then
        log "SUCCESS" "Permisos de ejecución aplicados al script Python"
    else
        log "ERROR" "Error al aplicar permisos de ejecución"
        return 1
    fi
    
    return 0
}

# Función para crear wrapper script
create_wrapper() {
    log "INFO" "Creando wrapper ejecutable..."
    
    # Crear backup si existe wrapper anterior
    if [ -f "$DEST_WRAPPER" ]; then
        log "INFO" "Creando backup de wrapper anterior..."
        cp "$DEST_WRAPPER" "$DEST_WRAPPER.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Crear el script wrapper
    cat > "$DEST_WRAPPER" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Wrapper para clarox.py
# Internet Bug Móvil DO - Desarrollador: Near365

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Ruta del script Python
SCRIPT_PATH="$PREFIX/bin/clarox.py"

# Verificar que el script Python existe
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}Error: clarox.py no encontrado en $SCRIPT_PATH${RESET}"
    echo -e "${BLUE}Ejecuta el instalador nuevamente: bash install.sh${RESET}"
    exit 1
fi

# Verificar que Python está instalado
if ! command -v python >/dev/null 2>&1; then
    echo -e "${RED}Error: Python no está instalado${RESET}"
    echo -e "${BLUE}Instala Python: pkg install python${RESET}"
    exit 1
fi

# Ejecutar el script Python con todos los argumentos
exec python "$SCRIPT_PATH" "$@"
EOF

    # Hacer ejecutable el wrapper
    if chmod +x "$DEST_WRAPPER"; then
        log "SUCCESS" "Wrapper creado y configurado correctamente"
    else
        log "ERROR" "Error al aplicar permisos al wrapper"
        return 1
    fi
    
    # Verificar que el wrapper funciona
    if [ -x "$DEST_WRAPPER" ]; then
        log "SUCCESS" "Wrapper instalado y verificado"
        return 0
    else
        log "ERROR" "El wrapper no es ejecutable"
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
    
    # Verificar que los archivos existen
    if [ ! -f "$DEST_SCRIPT" ]; then
        log "ERROR" "Script Python no encontrado"
        return 1
    fi
    
    if [ ! -f "$DEST_WRAPPER" ]; then
        log "ERROR" "Wrapper no encontrado"
        return 1
    fi
    
    # Verificar que Python puede importar el script
    if python -c "import sys; sys.path.insert(0, '$DEST_DIR'); exec(open('$DEST_SCRIPT').read())" 2>/dev/null; then
        log "SUCCESS" "Script Python verificado correctamente"
    else
        log "WARNING" "Puede haber problemas con el script Python"
    fi
    
    log "SUCCESS" "Instalación verificada"
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
    echo -e "${WHITE}2. Alternativamente: ${GREEN}python $DEST_SCRIPT${RESET}"
    echo -e "${WHITE}3. El programa te mostrará tu HWID único${RESET}"
    echo -e "${WHITE}4. Contacta a un suplidor para activar tu HWID${RESET}"
    echo -e "${WHITE}5. Una vez activado, el programa funcionará automáticamente${RESET}"
    echo ""
    echo -e "${CYAN}🔧 COMANDOS ÚTILES:${RESET}"
    echo -e "${WHITE}• Ejecutar: ${GREEN}clarox${RESET}"
    echo -e "${WHITE}• Ejecutar directo: ${GREEN}python $DEST_SCRIPT${RESET}"
    echo -e "${WHITE}• Detener: ${YELLOW}Ctrl + C${RESET}"
    echo -e "${WHITE}• Reinstalar: ${YELLOW}bash install.sh${RESET}"
    echo ""
    echo -e "${CYAN}📂 ARCHIVOS INSTALADOS:${RESET}"
    echo -e "${WHITE}• Script Python: ${GREEN}$DEST_SCRIPT${RESET}"
    echo -e "${WHITE}• Wrapper ejecutable: ${GREEN}$DEST_WRAPPER${RESET}"
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
    echo -e "${WHITE}• Requiere Python 3.6 o superior${RESET}"
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
    
    # Detectar arquitectura (solo informativo)
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
    
    # Crear wrapper ejecutable
    create_wrapper || {
        log "ERROR" "Fallo en la creación del wrapper"
        cleanup
        exit 1
    }
    
    # Crear directorio de configuración
    create_config_dir
    
    # Verificar instalación
    verify_installation || {
        log "WARNING" "Problemas detectados en la verificación"
    }
    
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