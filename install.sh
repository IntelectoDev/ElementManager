#!/data/data/com.termux/files/usr/bin/bash
# Script para Termux - Instalador de clarox con detección de arquitectura
# Internet Bug Móvil DO - Desarrollador: Near365
# Telegram: @Near365

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

URL_ARM64="https://raw.githubusercontent.com/IntelectoDev/ElementManager/master/clarox_ARM64"
URL_ARM32="https://raw.githubusercontent.com/IntelectoDev/ElementManager/master/clarox_ARM32"

DEST="$PREFIX/bin/clarox"
TEMP_FILE="/tmp/clarox_temp"

show_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║           INSTALADOR CLAROX - TERMUX                 ║${RESET}"
    echo -e "${CYAN}║              Internet Bug Móvil DO                   ║${RESET}"
    echo -e "${CYAN}║           Desarrollador: ${YELLOW}Near365${CYAN}                   ║${RESET}"
    echo -e "${CYAN}║             Telegram: @Near365                       ║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

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

check_internet() {
    log "INFO" "Verificando conexión a internet..."
    if curl -s --max-time 10 -I https://www.google.com >/dev/null 2>&1; then
        log "SUCCESS" "Conexión a internet verificada"
        return 0
    else
        log "ERROR" "No hay conexión a internet"
        return 1
    fi
}

check_termux() {
    if [ -z "$PREFIX" ] || [ ! -d "$PREFIX" ]; then
        log "ERROR" "Este script debe ejecutarse en Termux"
        echo -e "${RED}Por favor instala Termux desde F-Droid o Google Play Store${RESET}"
        exit 1
    fi
    log "SUCCESS" "Entorno Termux verificado"
}

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

update_repositories() {
    log "INFO" "Actualizando repositorios de Termux..."
    if pkg update -y >/dev/null 2>&1; then
        log "SUCCESS" "Repositorios actualizados correctamente"
    else
        log "WARNING" "Error al actualizar repositorios, continuando..."
    fi
}

install_dependencies() {
    log "INFO" "Instalando dependencias necesarias..."
    
    local packages=(
        "curl"
        "python"
        "python-pip"
        "libffi"
        "openssl"
        "libcrypt"
    )
    
    for package in "${packages[@]}"; do
        log "INFO" "Instalando $package..."
        if pkg install -y "$package" >/dev/null 2>&1; then
            log "SUCCESS" "$package instalado correctamente"
        else
            log "WARNING" "Error al instalar $package, continuando..."
        fi
    done
    
    log "INFO" "Instalando dependencias Python..."
    if pip install --upgrade pip cryptography >/dev/null 2>&1; then
        log "SUCCESS" "Dependencias Python instaladas"
    else
        log "WARNING" "Error al instalar dependencias Python"
    fi
}

download_binary() {
    log "INFO" "Descargando clarox ($ARCH_NAME)..."
    log "INFO" "URL: $URL"
    
    mkdir -p "$(dirname "$TEMP_FILE")"
    
    if curl -L \
        --retry 3 \
        --retry-delay 2 \
        --max-time 120 \
        --progress-bar \
        --user-agent "Mozilla/5.0 (Linux; Android 10; Mobile)" \
        -o "$TEMP_FILE" \
        "$URL"; then
        
        log "SUCCESS" "Descarga completada"
        return 0
    else
        log "ERROR" "Error al descargar el archivo desde $URL"
        return 1
    fi
}

verify_download() {
    log "INFO" "Verificando archivo descargado..."
    
    if [ ! -f "$TEMP_FILE" ]; then
        log "ERROR" "Archivo temporal no encontrado"
        return 1
    fi
    
    if [ ! -s "$TEMP_FILE" ]; then
        log "ERROR" "El archivo descargado está vacío"
        return 1
    fi
    
    log "SUCCESS" "Archivo verificado correctamente"
    return 0
}

install_binary() {
    log "INFO" "Instalando clarox en $DEST..."
    
    if [ -f "$DEST" ]; then
        log "INFO" "Creando backup de versión anterior..."
        cp "$DEST" "$DEST.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if mv "$TEMP_FILE" "$DEST"; then
        log "SUCCESS" "Archivo movido correctamente"
    else
        log "ERROR" "Error al mover el archivo a $DEST"
        return 1
    fi
    
    if chmod +x "$DEST"; then
        log "SUCCESS" "Permisos de ejecución aplicados"
    else
        log "ERROR" "Error al aplicar permisos de ejecución"
        return 1
    fi
    
    if [ -x "$DEST" ]; then
        log "SUCCESS" "Binario instalado y verificado"
        return 0
    else
        log "ERROR" "El binario no es ejecutable"
        return 1
    fi
}

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
    echo -e "${WHITE}• Detener: ${YELLOW}Ctrl + C${RESET}"
    echo -e "${WHITE}• Reinstalar: ${YELLOW}curl -sSL https://raw.githubusercontent.com/IntelectoDev/ElementManager/refs/heads/master/install.sh | bash${RESET}"
    echo ""
    echo -e "${CYAN}📞 SOPORTE:${RESET}"
    echo -e "${WHITE}• Telegram: ${GREEN}@Near365${RESET}"
    echo -e "${WHITE}• Para problemas o activación de HWID${RESET}"
    echo ""
    echo -e "${CYAN}⚠️  NOTAS IMPORTANTES:${RESET}"
    echo -e "${WHITE}• Necesitas conexión a internet para la activación inicial${RESET}"
    echo -e "${WHITE}• El programa mantiene la conexión automáticamente${RESET}"
    echo -e "${WHITE}• Solo funciona en dispositivos móviles con Termux${RESET}"
    echo ""
}

cleanup() {
    log "INFO" "Limpiando archivos temporales..."
    [ -f "$TEMP_FILE" ] && rm -f "$TEMP_FILE"
    log "SUCCESS" "Limpieza completada"
}

main() {
    show_header
    
    check_termux
    check_internet || {
        log "ERROR" "Se requiere conexión a internet para la instalación"
        exit 1
    }
    
    detect_architecture
    update_repositories
    install_dependencies
    
    download_binary || {
        log "ERROR" "Fallo en la descarga del binario"
        cleanup
        exit 1
    }
    
    verify_download || {
        log "ERROR" "Fallo en la verificación del archivo"
        cleanup
        exit 1
    }
    
    install_binary || {
        log "ERROR" "Fallo en la instalación del binario"
        cleanup
        exit 1
    }
    
    create_config_dir
    cleanup
    show_post_install_info
    
    log "SUCCESS" "¡Instalación completada exitosamente!"
}

trap cleanup EXIT INT TERM

main "$@"
