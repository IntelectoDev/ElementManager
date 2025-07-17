#!/data/data/com.termux/files/usr/bin/bash
# Script para Termux - Instalador de clarox con archivo Python ofuscado
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

# URLs del archivo Python ofuscado
URL_PYTHON="https://raw.githubusercontent.com/IntelectoDev/ElementManager/master/clarox_enc.py"

# Directorios y archivos
DEST_DIR="$PREFIX/bin"
PYTHON_FILE="$DEST_DIR/clarox.py"
SCRIPT_FILE="$DEST_DIR/clarox"
TEMP_FILE="/tmp/clarox_temp.py"
CONFIG_DIR="$HOME/.bugx_config"

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

# Función para detectar arquitectura (mantenido para compatibilidad)
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
            log "ERROR" "Arquitectura no compatible: $ARCH"
            echo -e "${RED}Arquitecturas soportadas: ARM64, ARM32${RESET}"
            exit 1
            ;;
    esac
    
    log "SUCCESS" "Arquitectura compatible para Python"
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
    
    # Lista de paquetes necesarios para Python
    local packages=(
        "curl"
        "python"
        "python-pip"
        "libffi"
        "openssl"
        "libcrypt"
        "proot"
        "python-cryptography"
        "python-requests"
        "python-urllib3"
        "python-certifi"
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
    log "INFO" "Instalando dependencias Python adicionales..."
    local pip_packages=(
        "cryptography"
        "requests"
        "urllib3"
        "certifi"
        "psutil"
        "colorama"
    )
    
    for pip_package in "${pip_packages[@]}"; do
        log "INFO" "Instalando $pip_package via pip..."
        if pip install --upgrade "$pip_package"; then
            log "SUCCESS" "$pip_package instalado correctamente"
        else
            log "WARNING" "Error al instalar $pip_package via pip"
        fi
    done
}

# Función para descargar el archivo Python ofuscado
download_python_file() {
    log "INFO" "Descargando archivo Python ofuscado..."
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
    log "INFO" "Verificando archivo Python descargado..."
    
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
    if head -n 1 "$TEMP_FILE" | grep -q "python" || file "$TEMP_FILE" | grep -q "Python"; then
        log "SUCCESS" "Archivo Python verificado correctamente"
        return 0
    else
        log "WARNING" "El archivo puede no ser un Python válido, continuando..."
        return 0
    fi
}

# Función para instalar el archivo Python
install_python_file() {
    log "INFO" "Instalando archivo Python en $PYTHON_FILE..."
    
    # Crear directorio de destino si no existe
    mkdir -p "$DEST_DIR"
    
    # Crear backup si existe versión anterior
    if [ -f "$PYTHON_FILE" ]; then
        log "INFO" "Creando backup de versión anterior..."
        cp "$PYTHON_FILE" "$PYTHON_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Mover el archivo temporal al destino final
    if mv "$TEMP_FILE" "$PYTHON_FILE"; then
        log "SUCCESS" "Archivo Python movido correctamente"
    else
        log "ERROR" "Error al mover el archivo a $PYTHON_FILE"
        return 1
    fi
    
    # Hacer ejecutable
    if chmod +x "$PYTHON_FILE"; then
        log "SUCCESS" "Permisos de ejecución aplicados al archivo Python"
    else
        log "ERROR" "Error al aplicar permisos de ejecución"
        return 1
    fi
    
    return 0
}

# Función para crear script wrapper
create_wrapper_script() {
    log "INFO" "Creando script wrapper en $SCRIPT_FILE..."
    
    # Crear backup si existe versión anterior
    if [ -f "$SCRIPT_FILE" ]; then
        log "INFO" "Creando backup del script wrapper anterior..."
        cp "$SCRIPT_FILE" "$SCRIPT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Crear el script wrapper
    cat > "$SCRIPT_FILE" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Wrapper script para clarox Python ofuscado
# Internet Bug Móvil DO - Desarrollador: Near365

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Archivo Python principal
PYTHON_FILE="$PREFIX/bin/clarox.py"

# Función para verificar dependencias
check_dependencies() {
    if ! command -v python > /dev/null 2>&1; then
        echo -e "${RED}Error: Python no está instalado${RESET}"
        echo -e "${YELLOW}Ejecuta: pkg install python${RESET}"
        exit 1
    fi
    
    if [ ! -f "$PYTHON_FILE" ]; then
        echo -e "${RED}Error: Archivo clarox.py no encontrado${RESET}"
        echo -e "${YELLOW}Ejecuta el instalador nuevamente${RESET}"
        exit 1
    fi
}

# Función para mostrar información de inicio
show_startup_info() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║                    CLAROX LAUNCHER                   ║${RESET}"
    echo -e "${BLUE}║              Internet Bug Móvil DO                   ║${RESET}"
    echo -e "${BLUE}║           Desarrollador: Near365                     ║${RESET}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${GREEN}[INFO] Iniciando clarox...${RESET}"
    echo -e "${YELLOW}[INFO] Presiona Ctrl+C para detener${RESET}"
    echo ""
}

# Función principal
main() {
    # Verificar dependencias
    check_dependencies
    
    # Mostrar información de inicio
    show_startup_info
    
    # Ejecutar el archivo Python ofuscado
    python "$PYTHON_FILE" "$@"
    
    # Capturar código de salida
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}[INFO] Clarox terminado correctamente${RESET}"
    else
        echo -e "${RED}[ERROR] Clarox terminado con código de error: $exit_code${RESET}"
    fi
    
    exit $exit_code
}

# Manejo de señales
trap 'echo -e "\n${YELLOW}[INFO] Deteniendo clarox...${RESET}"; exit 0' INT TERM

# Ejecutar función principal
main "$@"
EOF

    # Hacer ejecutable el script wrapper
    if chmod +x "$SCRIPT_FILE"; then
        log "SUCCESS" "Script wrapper creado y configurado"
        return 0
    else
        log "ERROR" "Error al aplicar permisos al script wrapper"
        return 1
    fi
}

# Función para crear directorio de configuración
create_config_dir() {
    log "INFO" "Creando directorio de configuración..."
    
    if mkdir -p "$CONFIG_DIR"; then
        chmod 700 "$CONFIG_DIR"
        log "SUCCESS" "Directorio de configuración creado: $CONFIG_DIR"
        
        # Crear archivo de configuración inicial
        cat > "$CONFIG_DIR/config.json" << 'EOF'
{
    "version": "1.0.0",
    "python_mode": true,
    "obfuscated": true,
    "install_date": "",
    "last_update": "",
    "hwid": "",
    "activated": false
}
EOF
        
        # Actualizar fecha de instalación
        sed -i "s/\"install_date\": \"\"/\"install_date\": \"$(date '+%Y-%m-%d %H:%M:%S')\"/" "$CONFIG_DIR/config.json"
        
        log "SUCCESS" "Archivo de configuración inicial creado"
    else
        log "WARNING" "Error al crear directorio de configuración"
    fi
}

# Función para verificar instalación
verify_installation() {
    log "INFO" "Verificando instalación..."
    
    # Verificar que el archivo Python existe
    if [ ! -f "$PYTHON_FILE" ]; then
        log "ERROR" "Archivo Python no encontrado"
        return 1
    fi
    
    # Verificar que el script wrapper existe
    if [ ! -f "$SCRIPT_FILE" ]; then
        log "ERROR" "Script wrapper no encontrado"
        return 1
    fi
    
    # Verificar que ambos son ejecutables
    if [ ! -x "$PYTHON_FILE" ] || [ ! -x "$SCRIPT_FILE" ]; then
        log "ERROR" "Archivos no son ejecutables"
        return 1
    fi
    
    # Verificar sintaxis Python básica
    if python -m py_compile "$PYTHON_FILE" 2>/dev/null; then
        log "SUCCESS" "Sintaxis Python verificada"
    else
        log "WARNING" "No se pudo verificar la sintaxis Python (archivo ofuscado)"
    fi
    
    log "SUCCESS" "Instalación verificada correctamente"
    return 0
}

# Función para mostrar información post-instalación
show_post_install_info() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║                 INSTALACIÓN COMPLETADA               ║${RESET}"
    echo -e "${GREEN}║                   (MODO PYTHON)                      ║${RESET}"
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
    echo -e "${WHITE}• Ejecutar directo: ${GREEN}python $PYTHON_FILE${RESET}"
    echo -e "${WHITE}• Detener: ${YELLOW}Ctrl + C${RESET}"
    echo -e "${WHITE}• Reinstalar: ${YELLOW}bash install.sh${RESET}"
    echo ""
    echo -e "${CYAN}📂 ARCHIVOS INSTALADOS:${RESET}"
    echo -e "${WHITE}• Archivo Python: ${GREEN}$PYTHON_FILE${RESET}"
    echo -e "${WHITE}• Script launcher: ${GREEN}$SCRIPT_FILE${RESET}"
    echo -e "${WHITE}• Configuración: ${GREEN}$CONFIG_DIR${RESET}"
    echo ""
    echo -e "${CYAN}📞 SOPORTE:${RESET}"
    echo -e "${WHITE}• Telegram: ${GREEN}@Near365${RESET}"
    echo -e "${WHITE}• Para problemas o activación de HWID${RESET}"
    echo ""
    echo -e "${CYAN}⚠️  NOTAS IMPORTANTES:${RESET}"
    echo -e "${WHITE}• Archivo Python ofuscado para mayor seguridad${RESET}"
    echo -e "${WHITE}• Necesitas conexión a internet para la activación inicial${RESET}"
    echo -e "${WHITE}• El programa mantiene la conexión automáticamente${RESET}"
    echo -e "${WHITE}• Compatible con todas las arquitecturas ARM${RESET}"
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
    
    # Detectar arquitectura (para compatibilidad)
    detect_architecture
    
    # Actualizar repositorios
    update_repositories
    
    # Instalar dependencias
    install_dependencies
    
    # Descargar archivo Python ofuscado
    download_python_file || {
        log "ERROR" "Fallo en la descarga del archivo Python"
        cleanup
        exit 1
    }
    
    # Verificar descarga
    verify_download || {
        log "ERROR" "Fallo en la verificación del archivo"
        cleanup
        exit 1
    }
    
    # Instalar archivo Python
    install_python_file || {
        log "ERROR" "Fallo en la instalación del archivo Python"
        cleanup
        exit 1
    }
    
    # Crear script wrapper
    create_wrapper_script || {
        log "ERROR" "Fallo en la creación del script wrapper"
        cleanup
        exit 1
    }
    
    # Crear directorio de configuración
    create_config_dir
    
    # Verificar instalación
    verify_installation || {
        log "ERROR" "Fallo en la verificación de la instalación"
        cleanup
        exit 1
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