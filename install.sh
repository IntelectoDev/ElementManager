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

# URLs del binario según arquitectura
URL_ARM64="https://raw.githubusercontent.com/IntelectoDev/ElementManager/master/clarox_ARM64"
URL_ARM32="https://raw.githubusercontent.com/IntelectoDev/ElementManager/master/clarox_ARM32"

# Directorio de instalación
DEST="$PREFIX/bin/clarox"

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
    echo -e "${WHITE}• Detener: ${YELLOW}Ctrl + C${RESET}"
    echo -e "${WHITE}• Reinstalar: ${YELLOW}bash install.sh${RESET}"
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

# Mostrar header
show_header

# Detectar arquitectura
ARCH=$(uname -m)
echo -e "${BLUE}[*] Detectando arquitectura: $ARCH${RESET}"

if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    echo -e "${GREEN}[*] Sistema ARM64 detectado. Descargando binario de 64 bits...${RESET}"
    URL="$URL_ARM64"
elif [[ "$ARCH" == "armv7l" || "$ARCH" == "armeabi" || "$ARCH" == "armv8l" ]]; then
    echo -e "${GREEN}[*] Sistema ARM32 detectado. Descargando binario de 32 bits...${RESET}"
    URL="$URL_ARM32"
else
    echo -e "${RED}[✗] Arquitectura no compatible: $ARCH${RESET}"
    echo -e "${RED}Arquitecturas soportadas: ARM64, ARM32${RESET}"
    exit 1
fi

# Descargar el binario
echo -e "${BLUE}[*] Descargando clarox...${RESET}"
curl -s -L -o "$DEST" "$URL"
if [ $? -ne 0 ]; then
    echo -e "${RED}[✗] Error al descargar el archivo desde $URL${RESET}"
    exit 1
fi

# Instalar dependencias necesarias
echo -e "${BLUE}[*] Instalando dependencias...${RESET}"
pkg update -y
pkg install -y python libffi python-cryptography

# Hacer ejecutable
chmod +x "$DEST"

# Verificar instalación
if [ -x "$DEST" ]; then
    echo -e "${GREEN}[✓] Instalado correctamente.${RESET}"
    
    # Mostrar información post-instalación
    show_post_install_info
    
    echo -e "${GREEN}¡Instalación completada exitosamente!${RESET}"
    echo -e "${CYAN}Ahora puedes ejecutarlo escribiendo: ${GREEN}clarox${RESET}"
else
    echo -e "${RED}[✗] Error en la instalación${RESET}"
    exit 1
fi

# Eliminar el script si fue ejecutado directamente
[ "$0" = "./install.sh" ] && rm -- "$0"
