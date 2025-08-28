#!/bin/bash

# ------------------- Configuración del servidor -------------------
HOST="127.0.0.1"
PORT=5000

# ------------------- Funciones de envío -------------------
tap() { local x=$1; local y=$2; echo "{\"action\":\"tap\",\"x\":$x,\"y\":$y}" | ncat $HOST $PORT; }
swipe() { local x1=$1; local y1=$2; local x2=$3; local y2=$4; local duration=$5; echo "{\"action\":\"swipe\",\"x1\":$x1,\"y1\":$y1,\"x2\":$x2,\"y2\":$y2,\"duration\":$duration}" | ncat $HOST $PORT; }
home() { echo "{\"action\":\"home\"}" | ncat $HOST $PORT; }
back() { echo "{\"action\":\"back\"}" | ncat $HOST $PORT; }

# ------------------- Función teclado -------------------
keyboard() {
    local input="$1"
    local char key x y
    local in_num=false

    # regex de números y símbolos (todo lo que se escribe desde NUMERIC)
    local NUMERIC_REGEX='[0-9@#\$%&*+\(\)!\"'"'"':;\/?,\.-]'

    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"

        # ==== Cambio automático entre layouts (antes de mapear alias) ====
        if [[ "$char" =~ $NUMERIC_REGEX ]]; then
            if [ "$in_num" = false ]; then
                eval "x=\${KEYBOARD_MAP_NUM_X}"
                eval "y=\${KEYBOARD_MAP_NUM_Y}"
                tap $x $y
                in_num=true
                sleep 0.2
            fi
        else
            if [ "$in_num" = true ]; then
                eval "x=\${KEYBOARD_MAP_ABC_X}"
                eval "y=\${KEYBOARD_MAP_ABC_Y}"
                tap $x $y
                in_num=false
                sleep 0.2
            fi
        fi

        # ==== Mapear alias de caracteres especiales ====
        case "$char" in
            " ")   key="SPACE" ;;
            "ñ")   key="ENYE" ;;
            "Ñ")   key="ENYEMAYUS" ;;
            "@")   key="AT" ;;
            "#")   key="HASH" ;;
            "$")   key="DOLLAR" ;;
            "%")   key="PERCENT" ;;
            "&")   key="AMP" ;;
            "*")   key="STAR" ;;
            "-")   key="MINUS" ;;
            "+")   key="PLUS" ;;
            "(")   key="LPAREN" ;;
            ")")   key="RPAREN" ;;
            "!")   key="EXCL" ;;
            "\"")  key="QUOTE" ;;
            "'")   key="APOST" ;;
            ":")   key="COLON" ;;
            ";")   key="SEMI" ;;
            "/")   key="SLASH" ;;
            "?")   key="QMARK" ;;
            ",")   key="COMMA" ;;
            ".")   key="DOT" ;;
            *)     key="$char" ;;
        esac


        if [[ "$input" == "SCI_SPECIAL_BACKSPACE" ]]; then
            eval "x=\${KEYBOARD_MAP_BACKSPACE_X}"
            eval "y=\${KEYBOARD_MAP_BACKSPACE_Y}"
            tap $x $y
            exit # saltar Shift y el resto del procesamiento
        fi

        # ==== Shift momentáneo para mayúsculas ====
        if [[ "$char" =~ [A-Z] || "$char" == "Ñ" ]]; then
            # Tap SHIFT antes de la letra
            eval "x=\${KEYBOARD_MAP_SHIFT_X}"
            eval "y=\${KEYBOARD_MAP_SHIFT_Y}"
            tap $x $y
            sleep 0.1
        fi

        # ==== Tap letra ====
        eval "x=\${KEYBOARD_MAP_${key}_X}"
        eval "y=\${KEYBOARD_MAP_${key}_Y}"
        if [ -z "$x" ] || [ -z "$y" ]; then
            echo "⚠ Coordenadas para '$char' (clave $key) no encontradas, ignorando"
            continue
        fi
        tap $x $y
        sleep 0.1

        # NO ES NECESARIO EN MI TECLADO (HACKERS KEYBOARD)
        # Tap SHIFT de vuelta si era mayúscula
        #if [[ "$char" =~ [A-Z] ]]; then
        #    eval "x=\${KEYBOARD_MAP_SHIFT_X}"
        #    eval "y=\${KEYBOARD_MAP_SHIFT_Y}"
        #    tap $x $y
        #    sleep 0.1
        #fi
    done
}

# ------------------- Wizard letras -------------------
config_keyboard() {
    echo "=== Wizard de configuración de teclado ==="
    echo "1. Habilita opciones de desarrollador y 'Ubicación del puntero'."
    echo "2. Escribe letra X Y, por ejemplo: a 100 1400"
    echo "3. Escribe EXIT para salir, SPECIAL para teclas especiales, NUMERIC para números/símbolos"

    while true; do
        read -p "> " line
        [[ "$line" == "EXIT" ]] && break
        [[ "$line" == "SPECIAL" ]] && special_mode && continue
        [[ "$line" == "NUMERIC" ]] && numeric_mode && continue

        set -- $line
        char=$1; x=$2; y=$3
        [[ -z "$char" || -z "$x" || -z "$y" ]] && { echo "Formato inválido"; continue; }
        [[ "$char" == "ñ" ]] && char="ENYE"
        [[ "$char" == "Ñ" ]] && char="ENYEMAYUS"
        [[ "$char" == " " ]] && char="SPACE"

        # Evitar duplicados
        grep -q "KEYBOARD_MAP_${char}_" "$0" && { read -p "Sobrescribir? (s/n): " resp; [[ "$resp" != "s" ]] && continue; sed -i "/KEYBOARD_MAP_${char}_/d" "$0"; }

        sed -i "/^# --- KEYBOARD MAP START ---$/a KEYBOARD_MAP_${char}_X=$x\nKEYBOARD_MAP_${char}_Y=$y" "$0"
        echo "Tecla '$char' guardada."
    done
    echo "Wizard terminado."
}

# ------------------- Wizard teclas especiales -------------------
special_mode() {
    echo "--- Modo SPECIAL ---"
    echo "Opciones: SPACE, SHIFT, ENTER, BACKSPACE, NUM, ABC, EXIT"
    while true; do
        read -p "Especial> " key
        [[ "$key" == "EXIT" ]] && break
        read -p "Coordenadas X Y de $key: " x y
        [[ -z "$x" || -z "$y" ]] && { echo "Formato inválido"; continue; }

        grep -q "KEYBOARD_MAP_${key}_" "$0" && { read -p "Sobrescribir? (s/n): " resp; [[ "$resp" != "s" ]] && continue; sed -i "/KEYBOARD_MAP_${key}_/d" "$0"; }

        sed -i "/^# --- KEYBOARD MAP START ---$/a KEYBOARD_MAP_${key}_X=$x\nKEYBOARD_MAP_${key}_Y=$y" "$0"
        echo "Tecla especial '$key' guardada."
    done
}

# ------------------- Wizard números y símbolos -------------------
numeric_mode() {
    echo "--- Modo NUMERIC/Símbolos ---"
    echo "Escribe tecla X Y, por ejemplo: 1 200 1400 o @ 300 1200"
    echo "Usa EXIT para salir del modo NUMERIC"

    while true; do
        read -p "Numeric> " key x y
        [[ "$key" == "EXIT" ]] && break
        [[ -z "$key" || -z "$x" || -z "$y" ]] && { echo "Formato inválido"; continue; }

        # Alias caracteres especiales
        case "$key" in
            "ñ") key="ENYE" ;;
            "@") key="AT" ;;
            "#") key="HASH" ;;
            "$") key="DOLLAR" ;;
            "%") key="PERCENT" ;;
            "&") key="AMP" ;;
            "*") key="STAR" ;;
            "-") key="MINUS" ;;
            "+") key="PLUS" ;;
            "(") key="LPAREN" ;;
            ")") key="RPAREN" ;;
            "!") key="EXCL" ;;
            "\"") key="QUOTE" ;;
            "'") key="APOST" ;;
            ":") key="COLON" ;;
            ";") key="SEMI" ;;
            "/") key="SLASH" ;;
            "?") key="QMARK" ;;
            ",") key="COMMA" ;;
            ".") key="DOT" ;;
        esac

        grep -q "KEYBOARD_MAP_${key}_" "$0" && { read -p "Sobrescribir? (s/n): " resp; [[ "$resp" != "s" ]] && continue; sed -i "/KEYBOARD_MAP_${key}_/d" "$0"; }

        sed -i "/^# --- KEYBOARD MAP START ---$/a KEYBOARD_MAP_${key}_X=$x\nKEYBOARD_MAP_${key}_Y=$y" "$0"
        echo "Tecla '$key' guardada."
    done
}

# ------------------- Mostrar teclado -------------------
show_keyboard() {
    echo "=== Teclas mapeadas ==="
    grep "^KEYBOARD_MAP_" "$0" | sed "s/^/ - /"
}

# ------------------- MAPEO DE TECLADO -------------------
# NO EDITAR MANUALMENTE ENTRE ESTOS COMENTARIOS
# --- KEYBOARD MAP START ---
KEYBOARD_MAP_BACKSPACE_X=650
KEYBOARD_MAP_BACKSPACE_Y=1450
KEYBOARD_MAP_SPACE_X=380
KEYBOARD_MAP_SPACE_Y=1512
KEYBOARD_MAP_ABC_X=80
KEYBOARD_MAP_ABC_Y=1515
KEYBOARD_MAP_x_X=207
KEYBOARD_MAP_x_Y=1435
KEYBOARD_MAP_DOT_X=550
KEYBOARD_MAP_DOT_Y=1510
KEYBOARD_MAP_COMMA_X=176
KEYBOARD_MAP_COMMA_Y=1510
KEYBOARD_MAP_QMARK_X=565
KEYBOARD_MAP_QMARK_Y=1435
KEYBOARD_MAP_SLASH_X=515
KEYBOARD_MAP_SLASH_Y=1435
KEYBOARD_MAP_SEMI_X=420
KEYBOARD_MAP_SEMI_Y=1435
KEYBOARD_MAP_COLON_X=360
KEYBOARD_MAP_COLON_Y=1435
KEYBOARD_MAP_APOST_X=292
KEYBOARD_MAP_APOST_Y=1435
KEYBOARD_MAP_QUOTE_X=210
KEYBOARD_MAP_QUOTE_Y=1435
KEYBOARD_MAP_EXCL_X=150
KEYBOARD_MAP_EXCL_Y=1435
KEYBOARD_MAP_RPAREN_X=683
KEYBOARD_MAP_RPAREN_Y=1360
KEYBOARD_MAP_LPAREN_X=609
KEYBOARD_MAP_LPAREN_Y=1360
KEYBOARD_MAP_PLUS_X=549
KEYBOARD_MAP_PLUS_Y=1360
KEYBOARD_MAP_MINUS_X=477
KEYBOARD_MAP_MINUS_Y=1360
KEYBOARD_MAP_STAR_X=400
KEYBOARD_MAP_STAR_Y=1360
KEYBOARD_MAP_AMP_X=330
KEYBOARD_MAP_AMP_Y=1360
KEYBOARD_MAP_PERCENT_X=228
KEYBOARD_MAP_PERCENT_Y=1360
KEYBOARD_MAP_DOLLAR_X=176
KEYBOARD_MAP_DOLLAR_Y=1360
KEYBOARD_MAP_HASH_X=115
KEYBOARD_MAP_HASH_Y=1360
KEYBOARD_MAP_AT_X=50
KEYBOARD_MAP_AT_Y=1360
KEYBOARD_MAP_0_X=683
KEYBOARD_MAP_0_Y=1260
KEYBOARD_MAP_9_X=609
KEYBOARD_MAP_9_Y=1260
KEYBOARD_MAP_8_X=549
KEYBOARD_MAP_8_Y=1260
KEYBOARD_MAP_7_X=477
KEYBOARD_MAP_7_Y=1260
KEYBOARD_MAP_6_X=400
KEYBOARD_MAP_6_Y=1260
KEYBOARD_MAP_5_X=330
KEYBOARD_MAP_5_Y=1260
KEYBOARD_MAP_4_X=228
KEYBOARD_MAP_4_Y=1260
KEYBOARD_MAP_3_X=176
KEYBOARD_MAP_3_Y=1260
KEYBOARD_MAP_2_X=115
KEYBOARD_MAP_2_Y=1260
KEYBOARD_MAP_1_X=42
KEYBOARD_MAP_1_Y=1260
KEYBOARD_MAP_NUM_X=70
KEYBOARD_MAP_NUM_Y=1522
KEYBOARD_MAP_ENTER_X=647
KEYBOARD_MAP_ENTER_Y=1515
KEYBOARD_MAP_SHIFT_X=63
KEYBOARD_MAP_SHIFT_Y=1414
KEYBOARD_MAP_m_X=573
KEYBOARD_MAP_m_Y=1440
KEYBOARD_MAP_n_X=508
KEYBOARD_MAP_n_Y=1440
KEYBOARD_MAP_b_X=439
KEYBOARD_MAP_b_Y=1440
KEYBOARD_MAP_v_X=361
KEYBOARD_MAP_v_Y=1440
KEYBOARD_MAP_c_X=293
KEYBOARD_MAP_c_Y=1440
KEYBOARD_MAP_z_X=155
KEYBOARD_MAP_z_Y=1440
KEYBOARD_MAP_ENYE_X=669
KEYBOARD_MAP_ENYE_Y=1350
KEYBOARD_MAP_ENYEMAYUS_X=669
KEYBOARD_MAP_ENYEMAYUS_Y=1350
KEYBOARD_MAP_k_X=529
KEYBOARD_MAP_k_Y=1350
KEYBOARD_MAP_j_X=467
KEYBOARD_MAP_j_Y=1350
KEYBOARD_MAP_g_X=318
KEYBOARD_MAP_g_Y=1350
KEYBOARD_MAP_f_X=243
KEYBOARD_MAP_f_Y=1350
KEYBOARD_MAP_d_X=186
KEYBOARD_MAP_d_Y=1350
KEYBOARD_MAP_s_X=119
KEYBOARD_MAP_s_Y=1350
KEYBOARD_MAP_p_X=673
KEYBOARD_MAP_p_Y=1256
KEYBOARD_MAP_i_X=531
KEYBOARD_MAP_i_Y=1268
KEYBOARD_MAP_u_X=476
KEYBOARD_MAP_u_Y=1265
KEYBOARD_MAP_y_X=397
KEYBOARD_MAP_y_Y=1256
KEYBOARD_MAP_t_X=320
KEYBOARD_MAP_t_Y=1270
KEYBOARD_MAP_r_X=240
KEYBOARD_MAP_r_Y=1261
KEYBOARD_MAP_e_X=176
KEYBOARD_MAP_e_Y=1262
KEYBOARD_MAP_w_X=110
KEYBOARD_MAP_w_Y=1268
KEYBOARD_MAP_q_X=46
KEYBOARD_MAP_q_Y=1265
KEYBOARD_MAP_l_X=604
KEYBOARD_MAP_l_Y=1345
KEYBOARD_MAP_o_X=600
KEYBOARD_MAP_o_Y=1265
KEYBOARD_MAP_h_X=400
KEYBOARD_MAP_h_Y=1345
KEYBOARD_MAP_a_X=45
KEYBOARD_MAP_a_Y=1352
KEYBOARD_MAP_A_X=45
KEYBOARD_MAP_A_Y=1352
KEYBOARD_MAP_B_X=439
KEYBOARD_MAP_B_Y=1440
KEYBOARD_MAP_C_X=293
KEYBOARD_MAP_C_Y=1440
KEYBOARD_MAP_D_X=186
KEYBOARD_MAP_D_Y=1350
KEYBOARD_MAP_E_X=176
KEYBOARD_MAP_E_Y=1262
KEYBOARD_MAP_F_X=243
KEYBOARD_MAP_F_Y=1350
KEYBOARD_MAP_G_X=318
KEYBOARD_MAP_G_Y=1350
KEYBOARD_MAP_H_X=400
KEYBOARD_MAP_H_Y=1345
KEYBOARD_MAP_I_X=531
KEYBOARD_MAP_I_Y=1268
KEYBOARD_MAP_J_X=467
KEYBOARD_MAP_J_Y=1350
KEYBOARD_MAP_K_X=529
KEYBOARD_MAP_K_Y=1350
KEYBOARD_MAP_L_X=604
KEYBOARD_MAP_L_Y=1345
KEYBOARD_MAP_M_X=573
KEYBOARD_MAP_M_Y=1440
KEYBOARD_MAP_N_X=508
KEYBOARD_MAP_N_Y=1440
KEYBOARD_MAP_O_X=600
KEYBOARD_MAP_O_Y=1265
KEYBOARD_MAP_P_X=673
KEYBOARD_MAP_P_Y=1256
KEYBOARD_MAP_Q_X=46
KEYBOARD_MAP_Q_Y=1265
KEYBOARD_MAP_R_X=240
KEYBOARD_MAP_R_Y=1261
KEYBOARD_MAP_S_X=119
KEYBOARD_MAP_S_Y=1350
KEYBOARD_MAP_T_X=320
KEYBOARD_MAP_T_Y=1270
KEYBOARD_MAP_U_X=476
KEYBOARD_MAP_U_Y=1265
KEYBOARD_MAP_V_X=361
KEYBOARD_MAP_V_Y=1440
KEYBOARD_MAP_W_X=110
KEYBOARD_MAP_W_Y=1268
KEYBOARD_MAP_X_X=207
KEYBOARD_MAP_X_Y=1435
KEYBOARD_MAP_Y_X=397
KEYBOARD_MAP_Y_Y=1256
KEYBOARD_MAP_Z_X=155
KEYBOARD_MAP_Z_Y=1440
# --- KEYBOARD MAP END ---

# ------------------- Menú principal -------------------
case "$1" in
    tap)      tap $2 $3 ;;
    swipe)    swipe $2 $3 $4 $5 $6 ;;
    home)     home ;;
    back)     back ;;
    keyboard) keyboard "$2" ;;
    config)   [[ "$2" == "keyboard" ]] && config_keyboard ;;
    show)     [[ "$2" == "keyboard" ]] && show_keyboard ;;
    *)        echo "Uso: $0 tap x y | swipe x1 y1 x2 y2 duration | home | back | keyboard TEXT | config keyboard | show keyboard" ;;
esac

