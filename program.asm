scrollOneLine MACRO from , to
    pushNew
    mov cx , from
    mov dx , to 
    mov ax,0601h
    mov bh,07 
    int 10h
    popNew
endm scrollOneLine

printLn MACRO loc
   moveCursor 0 , loc    
   printString line
endm printLn

chat_clicked_enter MACRO
	local cce_loop , cant_empty_message_send , cant_empty_message_send_path , no_scroll_required_for_me , finish_scrolling_func_for_me 
    cmp message[1] , 0
    jne cant_empty_message_send_path
        jmp cant_empty_message_send
    cant_empty_message_send_path:
    
    send_byte 'r'
	send_byte message[1]
	mov cl , message[1]
	mov si , 2
	cce_loop:
		send_byte message[si]
        inc si
		dec cl
	jnz cce_loop
    
    cmp my_location , 10
    jne no_scroll_required_for_me
        scrollOneLine 0 , 0A4fH
        moveCursor 0 , my_location
        jmp finish_scrolling_func_for_me
    no_scroll_required_for_me:
        inc my_location
        moveCursor 0 , my_location
    finish_scrolling_func_for_me:

    mov my_location_in_line[0] , 0
    mov message[1] , 0
    cant_empty_message_send:
ENDM chat_clicked_enter

chat_read_dynamic MACRO
    local chat_enter , finish , chat_ord_char , finish_crd_path
    mov ah , 1
    int 16h
	jnz finish_crd_path
        jmp finish
    finish_crd_path:

    cmp ah , 1
    jne back_space_chat 
        send_byte "e"
        mov message[1] , 0
        jmp start_of_choose_module
    back_space_chat:
    cmp al , 8
		jne chat_enter
		cmp message[1] , 0 ;; if size == 0  we should do nothing
		jne clear_buffer_label_path12
            jmp clear_buffer_label
        clear_buffer_label_path12:
		
        dec message[1]
        call remove_char_command
        jmp clear_buffer_label
	chat_enter:
	cmp al , 13
		je chat_ord_char_path53
            jmp chat_ord_char
        chat_ord_char_path53:
		chat_clicked_enter
        jmp clear_buffer_label
	chat_ord_char:
		cmp message[1] , 70
		jge clear_buffer_label
        store_position my_location_in_line
		mov bl , message[1]
		mov bh , 0
		mov message[bx + 2] , al
        display_char al
		inc message[1]

        clear_buffer_label:
        mov ah,0ch
        mov al,0
        int 21h
    finish:
ENDM chat_read_dynamic

chat_recieve_communicate MACRO
	local finish , crc_loop , recieve_message
    mov dx , 3FDH		; Line Status Register
	in al , dx 
	AND al , 1
	jz finish
	recieve_byte
    cmp al , "e"
    jne recieve_message
        mov message[1] , 0
        jmp start_of_choose_module
    recieve_message:
	cmp al , 'r'
	jne finish
		recieve_byte
		mov message_recieved[1] , al
		mov cl , al
		mov si , 2
		crc_loop:
			recieve_byte
			mov message_recieved[si] , al
			inc si
			dec cl
		jnz crc_loop
        call chat_control_recieve_position
        
        mov message_recieved[1] , 0
	finish:
ENDM chat_recieve_communicate

StartModule macro
	clearScreen
	mov initial_Position_start_x , 3
	NOT_VALID_NAME:	
        add initial_Position_start_x , 1
        moveCursor 20 , initial_Position_start_x 
        printString enter_your_name_message	
        add initial_Position_start_x , 1
        moveCursor 20 , initial_Position_start_x 
        ReadString userName	
        validateName userName[2]

    NOT_VALID_POINTS:
	    add initial_Position_start_x , 1
	    moveCursor 20 , initial_Position_start_x 
	    printString enter_your_initial_points_message
	    
	    add initial_Position_start_x , 1
	    moveCursor 20 , initial_Position_start_x 
	    
        ReadString initialPoints
        parse_int initialPoints[2] , initialPoints[1]
        push parsed_int_value
        pop initial_points
        
    ; parse_int initial_points_of_the_player[2] , initial_points_of_the_player[1]
    ; push parsed_int_value
    ; pop initial_points_real

    clearScreen
    both_finished userName[1] , userName_op[1]
    mov al , userName[1] ; 7
    mov ah , userName_op[1] ; 9
    cmp al , ah
    jnc mine_is_bigger
        mov cl , ah
        jmp finish_det_bigger
    mine_is_bigger:
        mov cl , al
    finish_det_bigger:
    
    ; ReadString initial_points_of_the_player

    mov si , 2
    loop_send_name:
        both_finished userName[si] ,userName_op[si]
        inc si
        dec cl
        jnz loop_send_name

    mov al , byte ptr initial_points[0]
    mov initialPoints[0] , al
    both_finished initialPoints[0] , initialPoints[1]
    mov al , initialPoints[1]
    mov byte ptr initial_points_op[0] , al 

    mov al , byte ptr initial_points[1]
    mov initialPoints[0] , al
    both_finished initialPoints[0] , initialPoints[1]
    mov al , initialPoints[1]
    mov byte ptr initial_points_op[1] , al
    mov ax , initial_points
    mov bx , initial_points_op
    mov initial_points_real , ax
    mov initial_points_real_op , bx
    moveCursor 0 , 0
endm StartModule

validateName macro name
    pushNew
    cmp name , 65
    jl NOT_VALID

    cmp name , 122
    jg NOT_VALID

    mov ax , 0
    
    clc
    cmp name , 97
    adc al , 0
    
    clc
    cmp name , 90
    adc ah , 0
    xor ah , 1
    
    and ah , al
    cmp ah , 1
    je NOT_VALID
    jmp okkkkk
    NOT_VALID:
      printString NOT_A_VALID_NAME_MESSAGE
      popNew
      jmp NOT_VALID_NAME
   
    okkkkk:       
    popNew
endm validateName

clearBuffer macro
    mov ah,0ch
    mov al,0
    int 21h
endm clearBuffer

changeMode macro m
     mov ah , 0
     mov al , m
     int 10h   
endm changeMode

choose_recieve_communicate macro
    local finish , finish_path1
    mov dx , 3FDH		; Line Status Register
	in al , dx 
	AND al , 1
	jnz finish_path1
        jmp finish
    finish_path1:
	recieve_byte
    cmp al , 'i'
    jne accept_invitation_chat
        mov accepted_from_other_chat , 1
        moveCursor 1 , 22
        print_t_size userName_op
        printString choose_chatting_message_invitian
        jmp finish
    accept_invitation_chat:
    cmp al , 'a'
	jne may_be_c
        ;;;;;;;;;;;;;;;;;; now i am the controller and i start
		jmp CHOOSE_CHAT_MODE_without_com
    
    may_be_c:
    cmp al , 'n'
    jne may_be_m
        mov accepted_from_other_game , 1
        moveCursor 1 , 22
        print_t_size userName_op
        printString choose_game_message_invitian
        jmp finish
    may_be_m:
    cmp al , 'm'
	jne finish
        mov invitatian_sender , 1
		jmp CHOOSE_game_MODE_without_com
	finish:
endm choose_recieve_communicate
five_seconds MACRO
    local easy_one , get_right_date , finish , timer_loop
    current_time
    cmp dl , 55
    jl easy_one
        sub dl , 55
        mov cl , 5
        sub cl , dl
        mov dl , cl
        inc dh
        jmp get_right_date
    easy_one:
        add dl , 5
    get_right_date:
        mov timer_temp_5 , dx
    timer_loop:
        current_time
        cmp dx , timer_temp_5
        jg finish
        jmp timer_loop
    finish:
ENDM five_seconds

control_inline_chat_in MACRO
    local cip_not_start
    cmp inline_message[1] , 0
    jne cip_not_start
        moveCursor 1 , 21
        printString clear_inline_position
        moveCursor 1 , 21
    cip_not_start:
ENDM control_inline_chat_in

print_t_size macro etbp
    local prm_ex_loop ,prm_finish
    mov cl , etbp[1]
    cmp cl , 0
    je prm_finish

    mov si , 2
    prm_ex_loop:
        mov ah,2 
        mov dl , etbp[si]
        int 21h
        inc si 
        dec cl
        jnz prm_ex_loop
    prm_finish:
endm print_t_size

inline_chat_recieve_control macro
    moveCursor 1 , 23
    printString clear_inline_position
    moveCursor 1 , 23
    print_t_size inline_message_op
endm inline_chat_recieve_control

inline_chat_clicked_enter MACRO
	local cce_loop , cant_empty_message_send ,no_scroll_required_for_me ,finish_scrolling_func_for_me
    cmp inline_message[1] , 0
    jne cant_empty_message_send_path
        jmp cant_empty_message_send
    cant_empty_message_send_path:
    
    send_byte 'r'
	send_byte inline_message[1]
	mov cl , inline_message[1]
	mov si , 2
	cce_loop:
		send_byte inline_message[si]
        inc si
		dec cl
	jnz cce_loop
    mov my_location_in_inline_chat[0] , 1
    mov inline_message[1] , 0
    cant_empty_message_send:
ENDM inline_chat_clicked_enter

inline_chat_read_dynamic MACRO message_var
    local chat_enter , finish , chat_ord_char ,clear_buffer, no_click_path1 , no_click_path2 , no_click_path3 , no_click_path4
    local transmit_no_click1_path , back_space_chat , clear_buffer_label_path12 , chat_ord_char_path53 , chat_ord_char , clear_buffer_label
    mov ah , 1
    int 16h
	jnz finish_crd_path
        jmp finish
    finish_crd_path:
    
    call check_power_up
    cmp dx , 1
    jne transmit_no_click1_path 
        jmp clear_buffer_label
    transmit_no_click1_path:
    
    cmp ah , 4bh
    jne no_click_path1
        jmp clear_buffer_label
    no_click_path1:
    cmp ah , 4dh
    jne no_click_path2
        jmp clear_buffer_label
    no_click_path2:
    cmp ah , 48h
    jne no_click_path3
        jmp clear_buffer_label
    no_click_path3:
    cmp ah ,  44h
    jne no_click_path4
        jmp finish
    no_click_path4:


    cmp ah , 1
    jne back_space_chat 
        send_byte "e"
        mov message_var[1] , 0
        jmp start_of_choose_module
    back_space_chat:
    cmp al , 8
		jne chat_enter
		cmp message_var[1] , 0 ;; if size == 0  we should do nothing
		jne clear_buffer_label_path12
            jmp clear_buffer_label
        clear_buffer_label_path12:
		dec my_location_in_inline_chat[0]
        dec message_var[1]
        call remove_char_command
        jmp clear_buffer_label
	chat_enter:
	cmp al , 13
		je chat_ord_char_path53
            jmp chat_ord_char
        chat_ord_char_path53:
		inline_chat_clicked_enter
        jmp clear_buffer_label
	chat_ord_char:
		cmp message_var[1] , 70
		jge clear_buffer_label
        control_inline_chat_in
        moveCursor my_location_in_inline_chat[0] , my_location_in_inline_chat[1]
        store_position my_location_in_inline_chat
		mov bl , message_var[1]
		mov bh , 0
		mov message_var[bx + 2] , al
        display_char al
		inc message_var[1]

        clear_buffer_label:
        mov ah,0ch
        mov al,0
        int 21h
    finish:
ENDM inline_chat_read_dynamic

control_mode_of_working macro
    local finish
    mov ah , 1
    int 16h
    jz finish
        cmp ah ,  44h
        jne finish
        toggle_modes
        clear_buffer
    finish:
endm control_mode_of_working

toggle_modes macro
    local another_thing1 , finish
    cmp mode_of_working , 0
    jne another_thing1
        mov mode_of_working , 1
        moveCursor my_location_in_inline_chat[0] , my_location_in_inline_chat[1]
        jmp finish
    another_thing1:
        mov mode_of_working , 0
        back_to_input_position
    finish:
endm toggle_modes

initialize_game_vars macro
    local loop1 , loop2
    mov cx , 8
    mov si , 0
    loop1:
        mov registers_values[si] ,0
        mov registers_values_op[si] ,0
        add si , 2
        dec cx
        jnz loop1
    mov cx , 16
    mov si , 0
    loop2:
        mov memory_values[si] , 0
        mov memory_values_op[si] , 0
        inc si
        dec cx
        jnz loop2
    mov clear_all_reg_power , 1
    mov mode_of_working , 0
    mov is_invalid_power , 0
    mov is_invalid_power2 , 0
    mov type_executing , 0
    mov position_after_clear[0] , 1 
    mov position_after_clear[1] , 19 
    mov my_location_in_inline_chat[0] , 1 
    mov my_location_in_inline_chat[1] , 21 
    mov input_string[1] , 0
endm initialize_game_vars

start_timer_of_two_dev macro
    local already_started , finish
    pushNew
    cmp start_timer , 0
    jne already_started
        current_time
        add dh , 2   ;;; 1 minute
        mov bird_game_start_time , dx
        mov start_timer , 1
        jmp finish
    already_started:
        current_time
        cmp dx , bird_game_start_time
        jl finish
        mov is_bird_game_running , 1
        send_byte "s"
    finish:
    popNew
endm start_timer_of_two_dev
generateRandomNumber MACRO randTo
pushNew
	mov ah, 00H 
    int 1ah  
    mov  ax, dx
    xor  dx, dx
    mov  cx, randTo    
    div  cx   
	mov rand , dx
popNew
ENDM generateRandomNumber
current_time macro
   push ax
   push cx
   mov ah,2ch
   int 21h
   mov dl , dh
   mov dh , cl 
   pop cx
   pop ax
endm current_time

advancedRandomGenerator MACRO randTo
    generateRandomNumber randTo
    generateRandomNumber rand
ENDM advancedRandomGenerator
initializeSquaresPos MACRO
	local isp_loop , isp_loop_ex
    pushNew
        mov bx , squaresNum
        add bx , bx
    isp_loop:
        generateRandomNumber 2
        cmp rand , 0
        je isp_left
            generateRandomNumber 305
            push rand
            pop squareX[bx - 2]
            mov squareY[bx - 2] , 0
            jmp before_isp_loop
        isp_left:
            generateRandomNumber 145
            push rand
            pop squareY[bx - 2]
            mov squareX[bx - 2] , 0
        before_isp_loop:
            sub bx , 2

            jz isp_loop_ex
				jmp isp_loop
			isp_loop_ex:
    popNew
ENDM initializeSquaresPos
changeSquarePos MACRO
    local csp_loop , x_inc , y_inc , x_dec , y_dec , before_csp_loop
    local csp_loop2 , before_csp_loop2 , x_ch_dec , x_ch_inc , y_ch_dec , y_ch_inc
    mov bx , squaresNum
    add bx , bx
    csp_loop:
        cmp squareX[bx - 2] , 400
        jge before_csp_loop
        cmp targetShoted[bx - 2] , 1
        je before_csp_loop
        x_inc:      
            cmp squareXInc[bx - 2] , 0
            je x_dec
            inc squareX[bx - 2]
            jmp y_inc
        x_dec:
            dec squareX[bx - 2]
        y_inc:
            cmp squareYInc[bx - 2] , 0
            je y_dec
            inc squareY[bx - 2]
            jmp before_csp_loop
        y_dec:
            dec squareY[bx - 2]
    before_csp_loop:
        sub bx , 2
        jnz csp_loop
    mov bx , squaresNum
    add bx , bx
    csp_loop2:
        ;;;;;;;;;;;;;;; added ;;;;;;;;;;;;;;;
        ; cmp squareX[bx - 2] , 400
        ; jge before_csp_loop2
        x_ch_dec:
            cmp squareX[bx - 2] , 305
            jl x_ch_inc
            mov squareXInc[bx - 2] , 0
            jmp y_ch_dec
        x_ch_inc:
            cmp squareX[bx - 2] , 0
            jg y_ch_dec
            mov squareXInc[bx - 2] , 1
        y_ch_dec:
            cmp squareY[bx - 2] , 145
            jl y_ch_inc
            mov squareYinc[bx - 2] , 0	
            jmp before_csp_loop2
        y_ch_inc:
            cmp squareY[bx - 2] , 0
            jg before_csp_loop2
            mov squareYInc[bx - 2] , 1
        before_csp_loop2:
            sub bx , 2
            jnz csp_loop2
ENDM changeSquarePos
drawRectangle MACRO fromX , fromY , lengthX , lengthY
local finish , LOOP1 , LOOP2 , beforeLoop1
pushNew
	mov cx , fromX
	mov dx , fromY
	mov si , lengthX
	mov di , lengthY
	mov finishLoop1 , cx
	mov finishLoop2 , dx
	add finishLoop1 , si
	add finishLoop2 , di
	mov al , 5
	mov ah , 0ch
	LOOP1:
		cmp cx , finishLoop1
		jge finish
		mov dx , fromY
		LOOP2:
			cmp dx , finishLoop2
			jge beforeLoop1
			int 10h
			inc dx
			jmp LOOP2
		beforeLoop1:
		inc cx
		jmp LOOP1
	finish:
popNew
ENDM drawRectangle
drawRectangleInfo MACRO  
	local finish , LOOP1 , LOOP2 , beforeLoop1
pushNew
	mov cx , arrXPos[bx]
	mov dx , arrYPos[bx]
	mov finishLoop1 , cx
	mov finishLoop2 , dx
	add finishLoop1 , 2
	add finishLoop2 , 5
	mov ah , 0ch
	LOOP1:
		cmp cx , finishLoop1
		jge finish
		mov dx , arrYPos[bx]
		LOOP2:
			cmp dx , finishLoop2
			jge beforeLoop1
			mov al , arrPixels[si] 
			int 10h
			inc si
			inc dx
			jmp LOOP2
		beforeLoop1:
		inc cx
		jmp LOOP1
	finish:
popNew
ENDM drawRectangleInfo
saveRectangleInfo MACRO 
	local finish , LOOP1 , LOOP2 , beforeLoop1
pushNew
	mov cx , arrXPos[bx]
	mov dx , arrYPos[bx]
	mov finishLoop1 , cx
	mov finishLoop2 , dx
	add finishLoop1 , 2
	add finishLoop2 , 5
	mov ah , 0dh
	LOOP1:
		cmp cx , finishLoop1
		jge finish
		mov dx , arrYPos[bx]
		LOOP2:
			cmp dx , finishLoop2
			jge beforeLoop1
			int 10h
			mov arrPixels[si] , al
			inc si
			inc dx
			jmp LOOP2
		beforeLoop1:
		inc cx
		jmp LOOP1
	finish:
popNew
ENDM saveRectangleInfo
getOldPixelsColors MACRO
	local loop1 , loop2 , beforeLoop1 , finish1
	pushNew
		mov di , si
		mov cx , arrXPos[bx]	
		mov dx , arrYPos[bx]
		mov finishLoop1 , cx	
		add finishLoop1 , 2
		mov finishLoop2 , dx
		add finishLoop2 , 5
		mov ah , 0dh
		LOOP1:
			cmp cx , finishLoop1
			jge finish1
			mov dx , arrYPos[bx]	
			LOOP2:
				cmp dx , finishLoop2
				jge beforeLoop1
				int 10h
				mov arrPixels[si] , al
				inc si
				inc dx
				jmp LOOP2
		beforeLoop1:
			inc cx
			jmp loop1
	finish1:
		mov si , di
	popNew
ENDM getOldPixelsColors
changeColorShot MACRO
		pushNew
		mov di , si
		local LOOP1_2 , LOOP2_2 , finish2 , deleteThisShot
		cmp arrYPos[bx] , 8
		jle deleteThisShot
		sub arrYPos[bx] , 8
		isTargetShotted ; will be changed
		mov cx , arrXPos[bx]
		mov dx , arrYPos[bx]
		mov finishLoop1 , cx	
		add finishLoop1 , 2
		mov finishLoop2 , dx
		add finishLoop2 , 5
		mov ah , 0ch
		LOOP1_2:
			cmp cx , finishLoop1
			jge finish2
			mov dx , arrYPos[bx]
			LOOP2_2:
				cmp dx , finishLoop2
				jge beforeLoop1_2
				mov al , squareColors[si] 
				int 10h
				inc si
				inc dx
				jmp LOOP2_2
		beforeLoop1_2:
			inc cx
			jmp loop1_2
	deleteThisShot:
		mov arrXPos[bx] , '$'
		mov arrYPos[bx] , '$'
	finish2:
		mov si , di
	popNew
ENDM changeColorShot
; bx given
changeShotPos MACRO
local CHP_clearShot , CHP_finish , CHP_clearShot_ex , CHP_shot_ex
    pushNew
        mov ax , 5
        mul bx
        mov si , ax ; si = bx * 5
        drawRectangleInfo  
        cmp arrYPos[bx] , 8
        jg CHP_clearShot_ex
            jmp CHP_clearShot
        CHP_clearShot_ex:
        sub arrYPos[bx] , 8
        _isTargetShotted
        cmp shotedNow , 0
        je CHP_shot_ex
            jmp CHP_clearShot
        CHP_shot_ex:
        mov ax , 5
        mul bx
        mov si , ax 
        saveRectangleInfo 
        drawRectangle arrXPos[bx] , arrYPos[bx] , 2 , 5
        jmp CHP_finish
    CHP_clearShot:
        mov arrYPos[bx] , '$'
        mov arrXPos[bx] , '$'
    CHP_finish:
    popNew
ENDM changeShotPos
addNewShot MACRO
local ANS_myLoop , ANS_beforeMyLoop , ANS_beforeMyLoop_ex , ANS_finish , ANS_finish_ex
pushNew
	mov bx , 0
	ANS_myLoop:
		cmp bx , 60
		jl ANS_finish_ex
			jmp ANS_finish 
		ANS_finish_ex:
		; jmp ANS_myLoop
		cmp arrXPos[bx] , '$'
		je ANS_beforeMyLoop_ex
			jmp ANS_beforeMyLoop
		ANS_beforeMyLoop_ex:
		mov si , gunPos
		mov arrXPos[bx] , si
		mov arrYPos[bx] , 175
		mov ax , 5
		mul bx
		mov si , ax
		saveRectangleInfo
		; drawRectangle si , 175 , 2 , 5
		jmp ANS_finish
	ANS_beforeMyLoop:
		add bx , 2
		jmp ANS_myLoop
	ANS_finish:
popNew
ENDM addNewShot
drawShot MACRO color
	local LOOP1 , LOOP2 , beforeLoop1 , finish
	mov cx , shotXPos
	mov dx , shotYPos
	mov si , cx
	add si , 8
	mov finishLoop1 , si
	mov si , dx
	sub si , 8
	mov finishLoop2 , si
	mov al , color
	mov ah , 0ch
	LOOP1:
		cmp cx , finishLoop1
		jge finish
		mov dx , shotYPos
		LOOP2:
			cmp dx , finishLoop2
			jle beforeLoop1
			int 10h	
			dec dx
			jmp LOOP2
	beforeLoop1:
		inc cx
		jmp LOOP1
	finish:

endm drawShot
; bx , si given
_isTargetShotted MACRO
    local before_its_loop , before_its_loop_ex , finish_its_loop , finish_its_loop_ex
	pushNew
		
        mov di , squaresNum
		add di , di
		its_loop:
			cmp squareX[di - 2] , 400
			jl before_its_loop_ex
				jmp before_its_loop
			before_its_loop_ex:
			isTargetShotted
			cmp shotedNow , 1
			jne finish_its_loop_ex
                jmp finish_its_loop
            finish_its_loop_ex:
		before_its_loop:
			sub di , 2
			jz its_loop_ex
				jmp its_loop
			its_loop_ex:
	finish_its_loop:
	popNew
ENDM _isTargetShotted
; bx , si , di given
isTargetShotted MACRO 
local shot , no_shot , no_shot_ex1 , no_shot_ex2 , no_shot_ex3 , no_shot_ex4
pushNew
	mov cx , squareX[di - 2] 
	mov dx , squareY[di - 2]
	cmp arrXPos[bx] , cx	
	jge no_shot_ex1
        jmp no_shot 
    no_shot_ex1:
	add cx , squareWH
	cmp arrXPos[bx] , cx
	jle no_shot_ex2
        jmp no_shot 
    no_shot_ex2:
	cmp arrYPos[bx] , dx
	jge no_shot_ex4
        jmp no_shot
    no_shot_ex4:
	add dx , squareWH
	cmp arrYPos[bx] , dx
	jle no_shot_ex3
        jmp no_shot 
    no_shot_ex3:
	mov shotedNow , 1
	mov targetShoted[di - 2] , 1 
    push squareX[di - 2]
    push squareY[di - 2]
    pop yPosTemp
    pop xPosTemp
    mov squareX[di - 2] , 400
    sub di , 2
    shr di , 1
    mov ax , 225
    mul di
    mov di , ax
    ;;;;;;;;;;;;;;;;;;
        sendIncreasedInitialPoints
    ;;;;;;;;;;;;;;;;;;
	drawOldColors xPosTemp , yPosTemp , squareColors[di]
    jmp shot
	no_shot:
		mov shotedNow , 0
	shot:
popNew
ENDM isTargetShotted

sendIncreasedInitialPoints macro
    pushNew
        shr bx , 1
        mov al , targetColors[bx]
        mov ah , 0
        add initial_points , ax
        send_byte targetColors[bx]
        call drawPositions
    popNew 
endm sendIncreasedInitialPoints

drawGun MACRO color
	local LOOP1 , LOOP2 , beforeLoop1 , finish
	mov cx , gunPos
	mov dx , 200
	mov si , cx
	add si , 8
	mov finishLoop1 , si
	mov si , dx
	sub si , 15
	mov finishLoop2 , si
	mov al , color
	mov ah , 0ch
	LOOP1:
		cmp cx , finishLoop1
		jge finish
		mov dx , 200
		LOOP2:
			cmp dx , finishLoop2
			jle beforeLoop1
			int 10h	
			dec dx
			jmp LOOP2
	beforeLoop1:
		inc cx
		jmp LOOP1
	finish:
ENDM drawGun

moveGunLeft MACRO 
	local finish
	cmp gunPos , 0
	jle finish
	drawGun 0
	sub gunPos , 5
	drawGun 5
	finish:
ENDM moveGunLeft

moveGunRight MACRO 
	local finish
	cmp gunPos , 312
	jge finish
	drawGun 0
	add gunPos , 5
	drawGun 5
	finish:
ENDM moveGunRight

shotTheGun MACRO
	mov gunShoted , 1	
	mov ax , gunPos
	add ax , 6
	mov shotXPos , ax
	mov shotYPos , 180
ENDM shotTheGun

_getOldColors MACRO
	local _goc_loop , before_goc_loop , before_goc_loop_ex
	pushNew
	mov bx , squaresNum
	add bx , bx
	mov di , squaresNum
	dec di
	mov ax , 225
	mul di
	mov di , ax ; di = squaresNum * 225
	_goc_loop:
		cmp squareX[bx - 2] , 400
		jl before_goc_loop_ex
			jmp before_goc_loop
		before_goc_loop_ex:
		push squareX[bx - 2]
		push squareY[bx - 2]
		pop yPosTemp
		pop xPosTemp
		getOldColors xPosTemp , yPosTemp , squareColors[di]
	before_goc_loop:
		sub di , 225
		sub bx , 2
		
		jnz _goc_loop
	popNew
ENDM _getOldColors
_drawOldColors MACRO
	local _doc_loop , before_doc_loop , before_doc_loop_ex
	pushNew
	mov bx , squaresNum
	add bx , bx
	mov di , squaresNum
	dec di
	mov ax , 225
	mul di
	mov di , ax ; di = squaresNum * 225
	_doc_loop:
		cmp squareX[bx - 2] , 400
		jl before_doc_loop_ex
			
			jmp before_doc_loop
		before_doc_loop_ex:
		push squareX[bx - 2]
		push squareY[bx - 2]
		pop yPosTemp
		pop xPosTemp
		drawOldColors xPosTemp , yPosTemp , squareColors[di]
	before_doc_loop:
		sub di , 225
		sub bx , 2
		jnz _doc_loop
	popNew
ENDM _drawOldColors
drawOldColors MACRO x , y , savedFrom
	local loop1 , loop2 , beforeLoop1 , finish
	pushNew
		mov cx , x
		mov dx , y
		mov finishLoop1 , cx	
		mov si , squareWH
		add finishLoop1 , si
		mov finishLoop2 , dx
		add finishLoop2 , si
		mov bx , 0
		mov ah , 0ch
		LOOP1:
			cmp cx , finishLoop1
			jge finish
			mov dx , y	
			LOOP2:
				cmp dx , finishLoop2
				jge beforeLoop1
				mov al , savedFrom[bx] 
				int 10h
				inc bx
				inc dx
				jmp LOOP2
		beforeLoop1:
			inc cx
			jmp loop1
	finish:
	popNew
ENDM drawOldColors
getOldColors MACRO x , y , saveColors
	local loop1 , loop2 , beforeLoop1 , finish
	pushNew
		mov cx , x	
		mov dx , y	
		mov finishLoop1 , cx	
		mov si , squareWH
		add finishLoop1 , si
		mov finishLoop2 , dx
		add finishLoop2 , si
		mov bx , 0
		mov ah , 0dh
		LOOP1:
			cmp cx , finishLoop1
			jge finish
			mov dx , y	
			LOOP2:
				cmp dx , finishLoop2
				jge beforeLoop1
				int 10h
				mov saveColors[bx] , al
				inc bx
				inc dx
				jmp LOOP2
		beforeLoop1:
			inc cx
			jmp loop1
	finish:
		cmp bx , 200
	popNew
ENDM getOldColors
drawSquares MACRO
    local ds_loop , before_ds_loop
    pushNew
    mov bx , squaresNum
    add bx , bx
    ds_loop:
        cmp squareX[bx - 2] , 400
        jge before_ds_loop
        cmp targetShoted[bx - 2] , 1
        je before_ds_loop
        mov ax , squareX[bx - 2]
        mov dx , squareY[bx - 2]
        push bx
        ; pushNew
            shr bx , 1 
            dec bx
            mov di , bx
        ; popNew
        pop bx
        mov cl , targetColors[di]
		mov xPosTemp , ax
		mov yPosTemp , dx
        drawSquare xPosTemp, yPosTemp , cl 
    before_ds_loop:
        sub bx , 2
        jnz ds_loop
    popNew
ENDM drawSquares
drawSquare MACRO x , y , color
	local drawSquareLoop1 , drawSquareLoop2 , beforeDrawSquareLoop1 , finish
	pushNew
	mov al , color
	mov ah , 0ch
	mov cx , x
	mov dx , y
	mov si , x
	mov di , y	
	add si , squareWH
	add di , squareWH
	drawSquareLoop1:
		cmp cx , si
		je finish
		mov dx , y
		drawSquareLoop2:
			cmp dx , di
			je beforeDrawSquareLoop1
			int 10h
			inc dx
			jmp drawSquareLoop2
		beforeDrawSquareLoop1:
			inc cx
			jmp drawSquareLoop1	
	finish:
	popNew
ENDM drawSquare

sleep MACRO d , c
	pushNew	
	mov cx , c
	mov dx , d
	mov ah , 86h
	int 15h
	popNew
ENDM sleep

changeAllShots MACRO
	local finish , finish_ch ,  myLoop , beforeMyLoop , beforeMyLoop_ch
	mov bx , 0
	myLoop:
		cmp bx , 60
		jl finish_ch
			jmp finish
		finish_ch:
		cmp arrXPos[bx] , '$'
		jne beforeMyLoop_ch
			jmp beforeMyLoop
		beforeMyLoop_ch:
		changeShotPos
	beforeMyLoop:
		add bx , 2
		jmp myLoop
	finish:
ENDM changeAllShots

start_game_timer MACRO
    local easy_one , get_right_date
    current_time
    cmp dl , 50
    jl easy_one
        sub dl , 50
        mov cl , 10
        sub cl , dl
        mov dl , cl
        inc dh
        jmp get_right_date
    easy_one:
        add dl , 10
    get_right_date:
    mov end_game_time , dx
ENDM start_game_timer

recieve_bird_communicate macro
    local path_nothing_sent , finish
    mov dx , 3FDH
    in al , dx 
    AND al , 1
    Jnz path_nothing_sent
        jmp finish
    path_nothing_sent:
        recieve_byte
        cmp al , "e"
        jne not_ending
            jmp finish_loop_bird_game
        not_ending:
        mov ah , 0
        add initial_points_op , ax
        call drawPositions
    finish:
endm recieve_bird_communicate

bird_game MACRO
    local myLoop , _space , left_exc , left , right ,not_me_12 ,not_me_13 ,initi_loop
    mov cx , 8
    mov si , 0
    initi_loop:
        mov targetShoted[si] , 0
        add si , 2
        dec cx
        jnz initi_loop
	clearScreen
    start_draw
    call drawPositions

    drawGun 5
    generateRandomNumber 4
    push rand
	pop squaresNum
    add squaresNum , 2
	initializeSquaresPos   
    mov squareX , 30
	mov squareY , 0
	mov squareX[2] , 0
	mov squareY[2] , 30
	mov squareX[4] , 90
	mov squareY[4] , 0
    mov squareX[6] , 150
	mov squareY[6] , 0
    mov squareX[8] , 0
	mov squareY[8] , 150 
    mov squareX[10] , 305
	mov squareY[10] , 150 
    mov squareX[12] , 0
	mov squareY[12] , 185 
    mov squareX[14] , 305
	mov squareY[14] , 100 
    mov targetColors[0] , 3
    mov targetColors[1] , 4
    mov targetColors[2] , 5
    cmp invitatian_sender , 1
    jne not_me_12
    start_game_timer
    not_me_12:

	_getOldColors
	myLoop:
        recieve_bird_communicate
        cmp invitatian_sender , 1
        jne not_me_13
            current_time
            cmp dx , end_game_time
            jl finish_loop_bird_game_path
                send_byte "e"
                jmp finish_loop_bird_game
            finish_loop_bird_game_path:
        not_me_13:

        changeAllShots
		_drawOldColors
		;readString temp
		changeSquarePos	
		;readString temp
		_getOldColors
        drawSquares 
        mov ah , 1
		int 16h
		jnz _space
			jmp afterChecking
		_space:
			cmp al , ' '
			je left_exc
				jmp left
			left_exc:
			addNewShot
			jmp afterChecking
		left:
			cmp ah , 4dh
			jne right
			moveGunRight
			jmp afterChecking
		right:
			cmp ah , 4bh
			jne afterChecking
			moveGunLeft
		afterChecking:
        clear_buffer
		sleep 0 , 1
	jmp myLoop
    finish_loop_bird_game:
    mov is_bird_game_running , 0
    mov start_timer , 0
    mov end_game_time , 100h
    mov bird_game_start_time , 100h

    mov input_string[1] , 0
    clear_buffer
    clearScreen
    start_draw
    
    call drawPositions
    mov position_after_clear[0] , 1
    mov position_after_clear[1] , 19
    mov inline_message[0] , 0
    mov my_location_in_inline_chat[0] , 1
    mov my_location_in_inline_chat[1] , 21
    back_to_input_position
ENDM bird_game
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_the_winner macro
    local loop_reg , loop_reg2 , finish , winner , loser
    mov cx , 8
    mov si , 0
    loop_reg:
        cmp registers_values[si] , 105eh
        jne winner_path21
            jmp loser
        winner_path21:
        add si , 2
        dec cx
        jnz loop_reg
    
    mov cx , 8
    mov si , 0
    loop_reg2:
        cmp registers_values_op[si] , 105eh
        je winner
        add si , 2
        dec cx
        jnz loop_reg2
    
    cmp initial_points , 0
    jle loser
    cmp initial_points_op , 0
    jle winner

    jmp finish
    loser:
        mov ah,0 
        mov al,03h
        int 10h 
        clearScreen
        printString looser_player_sen
        five_seconds
        jmp start_of_choose_module
    winner:
        mov ah,0 
        mov al,03h
        int 10h
        clearScreen
        printString winner_player_sen
        five_seconds
        jmp start_of_choose_module
    finish:
endm get_the_winner
both_finished macro sent_byte , recieved_byte
    local is_finished_reading2 ,  break_main2 , already_send_main12 , already_recieved_main12
    mov is_data_recieved2 , 0
    mov is_data_sent2 , 0
    is_finished_reading2:
            cmp is_data_sent2 , 1
            je already_send_main12
                mov is_data_sent2 , 1
                send_byte sent_byte
            already_send_main12:

            cmp is_data_recieved2 , 1
            je already_recieved_main12
                mov is_data_recieved2 , 1
                recieve_byte
                mov recieved_byte , al
            already_recieved_main12:
            
            cmp is_data_sent2 , 1
            jne is_finished_reading2
                cmp is_data_recieved2 , 1
                jne is_finished_reading2
                jmp break_main2
        jmp is_finished_reading2
        break_main2:
endm both_finished

sending_in_main macro
    cmp is_data_sent , 1
    je already_sent_main
        mov dx , 3FDH        
        In al , dx
        AND al , 00100000b
        JZ cant_send_any_thing
            mov is_data_sent , 1
            send_byte userName[1]
            mov cl , userName[1]
            mov si , 2
            main_send_name:
            send_byte userName[si]
            inc si
            dec cl
            jne main_send_name
            send_byte byte ptr initial_points[0]
            send_byte byte ptr initial_points[1]
            send_byte level
        cant_send_any_thing:
    already_sent_main:
endm sending_in_main

clearScreen  macro
	pushNew 
	mov ax,0600h
	mov bh,07
	mov cx,0 
	mov dx,184FH
	int 10h
	popNew
endm clearScreen

ReadString macro mem
    mov ah , 0AH 
    mov dx , offset mem
    int 21h 
endm ReadString

initialScreen MACRO
    local not_my_res_in_initial
    clearScreen
    moveCursor 0 , 0
    
    cmp invitatian_sender , 1
    jne not_my_res_in_initial
        printString levelString
        ReadString level_temp
        clearScreen
        moveCursor 0 , 0
    not_my_res_in_initial:
    
    clearScreen
    moveCursor 0 , 0
    printString invalid_char_sentance1
    ReadString invalid_char_read
    mov al , invalid_char_read[2]
    mov invalid_char1[0] ,  al
ENDM initialScreen

level2InitialScreen MACRO
    local l2I_myLoop , l2I_finish , l2I_finish_ex
    clearScreen
    mov si , 0
    mov bx , 0
    l2I_myLoop:
        cmp bx , 16
        jl l2I_finish_ex
            jmp l2I_finish
        l2I_finish_ex:
        printString registers_names[si]
        ReadString regInValue
        parse_int regInValue[2] , regInValue[1]
        push parsed_int_value
        pop registers_values[bx]
        add si , 4
        add bx , 2
        ; clearScreen
        moveCursor 0 , bl
        jmp l2I_myLoop
    
    l2I_finish:
ENDM level2InitialScreen

back_to_input_position MACRO
    moveCursor position_after_clear[0] , position_after_clear[1]
ENDM back_to_input_position

invalid_minus_1 MACRO me_or_op
    local it_is_valid_proc19
    cmp is_invalid , 1
    jne it_is_valid_proc19
        cmp invalid_syntax_or_norm , 0
        jne it_is_valid_proc19
        dec me_or_op
    it_is_valid_proc19:    
ENDM invalid_minus_1

store_position macro pos_aft_cl
    mov ah,3h
    mov bh,0h
    int 10h
    add dl , 1
    mov pos_aft_cl[0] , dl
    mov pos_aft_cl[1] , dh
endm store_position

clear_buffer MACRO
    mov ah,0ch
    mov al,0
    int 21h    
ENDM clear_buffer

execute_for_opponent MACRO
    call put_in_temp
    call execute_command_final
    call back_to_normal
ENDM execute_for_opponent

drawLineVertical MACRO x , YTO
  local loop1 , finish
  mov cx , x
  mov dx , 0
  mov ah , 0ch
  mov al , 5
  LOOP1:
    cmp dx , YTO
    jge finish
    int 10h
    inc dx
    jmp LOOP1
  finish:
ENDM drawLineVertical

drawLineHorizontal MACRO y
  local loop1 , finish
  mov cx , 0
  mov dx , y
  mov ah , 0ch
  mov al , 5
  LOOP1:
    cmp cx , 320
    jge finish
    int 10h
    inc cx
    jmp LOOP1
  finish:
ENDM drawLineHorizontal

start_draw macro
    mov ax, 0013h
    mov bx, 0100h    
    INT 10h
    drawLineVertical 160 , 160
    drawLineHorizontal 160
    ; drawLineHorizontal 180
    moveCursor 6 , 1
    printString sentance_1
    moveCursor 25 , 1
    printString sentance_2
endm start_draw

display_char MACRO val_char
    mov ah , 2 
    mov dl , val_char
    int 21h
ENDM display_char

conf MACRO
    mov dx , 3fbh 			; Line Control Register
    mov al , 10000000b		;Set Divisor Latch Access Bit
    out dx,al
    
    mov dx,3f8h			
    mov al,0ch			
    out dx,al

    mov dx,3f9h
    mov al,00h
    out dx,al

    mov dx,3fbh
    mov al, 00011011b

    out dx,al
ENDM conf

send_byte MACRO value
    local AGAIN
    mov dx , 3FDH
    AGAIN:
        In al , dx
        AND al , 00100000b
  	JZ AGAIN

  	mov dx , 3F8H
  	mov al , value
  	out dx , al 
ENDM send_byte

recieve_byte MACRO
    local CHK
    mov dx , 3FDH		; Line Status Register
	CHK:
        in al , dx 
  		AND al , 1
  	JZ CHK

    mov dx , 03F8H
    in al , dx
ENDM recieve_byte

clear_all_reg macro
    local myLoop
    mov si , 0
    mov cx , 8
    myLoop:
        mov registers_values[si] , 0
        mov registers_values_op[si] , 0
        add si , 2
        dec cx
        jnz myLoop
    call drawPositions
endm clear_all_reg

clicked_enter MACRO
    ;; if 0 =>  sendCommand ;else if 1 => myown execute and send "t" else if 2=> both execute and sendCommand
    ;; minus for powerUps

    cmp type_executing , 2
    jne not_type_2
        sub initial_points , 3
        send_byte "a" ;; all   
    not_type_2:

    cmp type_executing , 1
    je no_send 
        call sendCommand
        execute_for_opponent
        invalid_minus_1 initial_points
    no_send:

    cmp type_executing , 0
    je not_my_device
        call execute_command_final
        cmp type_executing , 2
        je not_again_case_2
            invalid_minus_1 initial_points
        not_again_case_2:
    not_my_device:

    cmp type_executing , 1
    jne change_turn
        send_byte "t"
        je not_level2_cpu
            sub initial_points , 5 ;; rule
        not_level2_cpu:
        call sendCommand
    change_turn:

    ; cmp is_invalid_power , 1
    ; jne not_forbidden_send2
    ;     mov is_invalid_power , 0
    ;     mov al , invalid_char_temp
    ;     mov invalid_char1 , al
    ; not_forbidden_send2:
    ;;;;;;;;;;;;;;;;;;
    call drawPositions
    mov position_after_clear[0] , 1
    mov position_after_clear[1] , 19
    mov turn , 0
    mov type_executing , 0
    mov input_string[1] , 0 ;
ENDM clicked_enter

power_clear_reg MACRO
    local not_clear_reg
    cmp clear_all_reg_power , 2
    je path_not_clear
        jmp not_clear_reg
    path_not_clear:
        clear_all_reg
        moveCursor position_after_clear[0] , position_after_clear[1]
        sub initial_points , 30
        send_byte "c"
        mov clear_all_reg_power , 0
        call drawPositions        
    not_clear_reg:
ENDM power_clear_reg

game_read_dynamic MACRO com
    local no_click , can_input, is_ok , finish , transmit_finish1 ,transmit_no_click1,transmit_no_click1_path , transmit_finish1_path
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; transmit cause there was an error that the distance between the lable and jmp is so long
    ;;;; note => i solved transmit problem using procedures
    mov ah , 1
    int 16h
    jnz transmit_finish1_path
        jmp transmit_finish1
    transmit_finish1_path:
        ;;;;;;;;;;;;;;;;;;; power ups
        call check_power_up
        cmp dx , 1

        jne transmit_no_click1_path 
            jmp transmit_no_click1
        transmit_no_click1_path:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;
        cmp ah ,  44h
        jne no_click_path4
            jmp finish
        no_click_path4:

        cmp ah , 1
        jne back_space_label123
            send_byte "e"
        jmp start_of_choose_module
        back_space_label123:

        cmp turn , 0
        jne transmit_no_click2_path 
            jmp transmit_no_click1
        transmit_no_click2_path:
        
        cmp ah , 4bh
        jne no_click_path1
            jmp no_click
        no_click_path1:
        cmp ah , 4dh
        jne no_click_path2
            jmp no_click
        no_click_path2:
        cmp ah , 48h
        jne no_click_path3
            jmp no_click
        no_click_path3:

        cmp al , 8 ; if click backspace
        jne is_ok
            ;;;;;;;;;; if backspace
            cmp com[1] , 0 ;; if size == 0  we should do nothing
            jne transmit_no_click3_path 
                jmp transmit_no_click1
            transmit_no_click3_path:
            dec com[1]
            call remove_char_command
            dec position_after_clear[0]
            jmp transmit_no_click1

        is_ok: ;; if click enter
            cmp al , 13
            je can_input_path12
                jmp can_input
            can_input_path12:
                clicked_enter
        jmp no_click        
        ;;;;;;;;;;;;;;;;;;;;;;;;;;; end of enter  !!!!!!!! important
        transmit_finish1:
            jmp finish
        transmit_no_click1:
            jmp no_click
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;
            can_input: ;; if click any normal char we put it in the command var
            call control_input_position
            back_to_input_position
            store_position position_after_clear
            display_char al
            ;;;;;;;;;;;;
            mov bh , 0
            mov bl, com[1]
            inc com[1]
            mov com[bx + 2] , al
        no_click:
        mov ah,0ch
        mov al,0
        int 21h
    finish:    
ENDM game_read_dynamic

recieve_communicate MACRO
    local nothing_sent , recieve_normally , both_processor , crc_loop , recieve_message
    mov dx , 3FDH
    in al , dx 
    AND al , 1
    Jnz path_nothing_sent
        jmp nothing_sent
    path_nothing_sent:
        recieve_byte ;;; type of recieved signal
        cmp al , "e"
        jne recieve_message
            mov inline_message[1] , 0
            jmp start_of_choose_module
        recieve_message:
        cmp al , 'r'
        jne forbidden_char_label
            recieve_byte
            mov inline_message_op[1] , al
            mov cl , al
            mov si , 2
            crc_loop:
                recieve_byte
                mov inline_message_op[si] , al
                inc si
                dec cl
            jnz crc_loop
            inline_chat_recieve_control
            jmp nothing_sent
        
        forbidden_char_label:
        cmp al , "f"
        jne both_processor
            recieve_byte ;; forbidden character
            mov invalid_char1 , al
            sub initial_points_op , 8
            call drawPositions
            back_to_input_position
            jmp nothing_sent

        both_processor:
        cmp al , "a"
        jne recieve_normally
            recieve_byte ;; both processors
            call recieve_command
            call control_recieve_position
            call exchange_invalid_char
            call execute_command_final
            invalid_minus_1 initial_points_op
            execute_for_opponent
            call exchange_invalid_char
            sub initial_points_op , 3
            mov input_string[1] , 0
            call drawPositions
            mov turn , 1
            jmp nothing_sent
        recieve_normally:
        cmp al , 0 ;;;;; if 0 => we recieve a command and executed it normally
        jne clear_reg_lable
            call recieve_command
            call control_recieve_position
            call exchange_invalid_char

            call execute_command_final
            
            call exchange_invalid_char
            invalid_minus_1 initial_points_op
            mov input_string[1] , 0
            call drawPositions
            
            mov turn , 1 ;;;;;;; now it's my turn
            jmp nothing_sent
        clear_reg_lable:
            cmp al , "c"
            jne my_turn
            sub initial_points_op , 30
            clear_all_reg
            jmp nothing_sent
        my_turn: ;; if "t" we take the turn ;; myProcessor
            cmp al , "t"
            jne start_the_game_order
            recieve_byte
            call recieve_command
            call control_recieve_position
            call exchange_invalid_char
            
            execute_for_opponent
            
            call exchange_invalid_char
            invalid_minus_1 initial_points_op
            cmp level , 2
            je not_level2_rc2
                sub initial_points_op , 5 ;; rule
            not_level2_rc2:
            ; sub initial_points_op , 5
            call drawPositions
            mov input_string[1] , 0
            mov turn , 1
            jmp nothing_sent
        start_the_game_order:
            cmp al , "s"
            jne increase_initial_points
            mov is_bird_game_running , 1
            jmp nothing_sent
        increase_initial_points:
            mov ah , 0
            add initial_points_op , ax
            call drawPositions
        ;;;; in case invalid syntax we send bit with value "m"
    nothing_sent:    
ENDM recieve_communicate

validate_single_operand macro operand
    local direct_mode , direct_mode1 , direct , reg , valid , invalid , finish , before_direct , reg_8 , memory , or1 , or2 , addressing4
    local invalid_change1 , invalid_change2 , invalid_change3 , invalid_change4 , invalid_change5 , invalid_change6 , invalid_change7 , invalid_change8 , invalid_change9 
    local invalid_change10 , invalid_change11 , invalid_change12 , or1_change , or2_change , reg_change1 , valid_change2 , addressing4_change , direct_mode_change
    mov cl , operand[0]
    cmp cl , 0
    jne memory
    mov has_operand , 0
    jmp valid
    ; memory
    memory:
    mov has_operand , 1
    cmp operand[1] , '['
    je direct_mode_change     
        jmp direct_mode
    direct_mode_change:
    cmp cl , 3
    je addressing4_change
        jmp addressing4
    addressing4_change:
    checkHexa operand[2]
    cmp hexa , 0
    jne invalid_change1
        jmp invalid
    invalid_change1:
    cmp operand[3] , ']'
    je invalid_change2
        jmp invalid
    invalid_change2:
    mov ah , operand[2]
    mov al , 1
    jmp valid
    addressing4:
    cmp cl , 4
    je invalid_change3
        jmp invalid
    invalid_change3:
    checkReg operand[2]
    cmp register_type , 1
    je or1_change
        jmp or1 
    or1_change:
    mov ah , 1
    mov al , 5 ; type
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bx , 0fh
    cmp registers_values[2] , bx
    jle invalid_change4
        jmp invalid
    invalid_change4:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
    jmp valid
    or1:
    cmp register_type , 4
    je or2_change
        jmp or2
    or2_change:
    mov ah , 4
    mov al , 5
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bx , 0fh
    cmp registers_values[8] , bx
    jle invalid_change5
        jmp invalid
    invalid_change5:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp valid
    or2:
    cmp register_type , 5
    je invalid_change6
        jmp invalid
    invalid_change6:
    mov ah , 5
    mov al , 5
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bx , 0fh
    cmp registers_values[10] , bx
    jle invalid_change7
        jmp invalid
    invalid_change7:

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp valid  
    ; direct
    direct_mode:
    mov ah , 0
    cmp operand[1] , '0'
    jge direct_mode1
    jmp reg  
    direct_mode1:
    cmp operand[1] , '9'
    jle reg_change1
        jmp reg
    reg_change1:
    cmp operand[1] , '0'
    je before_direct ;changed
    mov ah , 1
    before_direct: 
    mov bx , 2
    direct:
    cmp bl , cl 
    mov al , 2
    jle valid_change2
        jmp valid
    valid_change2:
    add ah , 1
    cmp ah , 5
    jl invalid_change8
        jmp invalid
    invalid_change8:
    checkHexa operand[bx]
    cmp hexa , 0
    jne invalid_change9
        jmp invalid
    invalid_change9:
    inc bx
    jmp direct         
    ; register
    reg:
    cmp cl , 2 
    je invalid_change10
        jmp invalid
    invalid_change10: 
    checkReg operand[1]
    cmp register_type , 15
    jle invalid_change11
        jmp invalid
    invalid_change11: 
    cmp register_type , 0
    jge invalid_change12
        jmp invalid
    invalid_change12: 
    cmp register_type , 8
    jge reg_8
    mov ah , register_type
    mov al , 3
    jmp valid
    reg_8:
    mov ah , register_type
    mov al , 4
    jmp valid
    ; else   
    invalid:  
    mov ax , 0
    mov bl , 0
    jmp finish 
    valid: 
    
    finish:
endm validate_single_operand

compareString macro str1 , str2
    local not_valid_for_game_validation , finish    
    mov dh , str1[0]
    mov dl , str2[0]
    cmp dh , dl
    jne not_valid_for_game_validation
    mov dh , str1[1]
    mov dl , str2[1]
    cmp dh , dl
    jne not_valid_for_game_validation
    mov dh , str1[2]
    mov dl , str2[2]
    cmp dh , dl
    jne not_valid_for_game_validation
    mov dx , 1
    jmp finish
    not_valid_for_game_validation:    
    mov dx , 0
    finish:
endm compareString

checkReg macro input_reg
    local check_reg_loop , finish , continue_reg_loop
    mov register_type , 20
    mov ah , input_reg[0]
    mov al , input_reg[1]
    
    mov bx , 0
    check_reg_loop:
        cmp bx , 16
            je finish         
        mov si , bx
        add si , bx
        cmp registers[si] , ah
        jne continue_reg_loop
        cmp registers[si + 1] , al
        jne continue_reg_loop
        mov register_type , bl
        jmp finish
        continue_reg_loop:
        inc bx
        jmp check_reg_loop
    ;; must be deleted    
    finish:        
endm checkReg

checkHexa macro char
    local p1 , p2 , p3 , p4 , p5 , true , false , finish
    cmp char[0] , '0'
    jge p1 
    jmp p2
    p1:
    cmp char[0] , '9'
    jle true 
    p2:
    cmp char[0] , 'a'
    jge p3
    jmp p4
    p3:
    cmp char[0] , 'f'
    jle true
    p4:
    cmp char[0] , 'A'
    jge p5
    jmp false
    p5:
    cmp char[0] , 'F'
    jle true
    jmp false
    true:
    mov hexa , 1
    jmp finish
    false:
    mov hexa , 0
    finish:
endm checkHexa

last_validation macro
    local reg_8 , reg_16 , invalid , valid , finish , memory2 , mem_mem , invalid_lv1 , invalid_lv2 , invalid_lv3 , invalid_lv111
    ; invalid type
    cmp operand1_type , 0
    jne invalid_lv1
        jmp invalid
    invalid_lv1:
    cmp has_operand , 0
    jne invalid_lv111
        jmp valid
    invalid_lv111:
    cmp operand2_type , 0
    jne invalid_lv2
        jmp invalid
    invalid_lv2:
    cmp operand1_type , 2
    jne invalid_lv3
        jmp invalid
    invalid_lv3:

    ; memory to memory
    cmp operand1_type , 1
    jne memory2
    cmp operand2_type , 1
    je invalid
    cmp operand2_type , 5
    je invalid
    jmp valid
    memory2:
    cmp operand1_type , 5
    jne reg_16
    cmp operand2_type , 1
    je invalid
    cmp operand2_type , 5
    je invalid
    jmp valid
    ;;;;;;;;;;;;;;; size mismatch
    reg_16:
    cmp operand1_type , 3     
        jne reg_8 
        cmp operand2_type , 4
        je invalid
        cmp operand2_type , 2 ; is a number
        jne valid
        cmp operand2_more_info , 4 ; size mismatch
        
        jg invalid
            ;;; added ;;;;;;;;;;;;;;;;;;;;;;;;;;;
            mov bh , 0
            mov bl , operand2_more_info
            mov input_command1[bx] , 0
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        jmp valid
    reg_8:
    cmp operand1_type , 4
        jne invalid ; if happened there is something wrong
        cmp operand2_type , 3
        je invalid
        cmp operand2_type , 2
        jne valid
        cmp operand2_more_info , 2
        jg invalid
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            mov bh , 0
            mov bl , operand2_more_info
            mov input_command1[bx] , 0  
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        jmp valid
    invalid:
        mov valid_operands , 0
        jmp finish
    valid:
        mov valid_operands , 1
    finish:        

endm last_validation

execute_command_1_operand macro
    local memory_reg , reg_8 , reg_16 , finish , exco_memory_reg , exco_reg_16 , exco_reg_8
        cmp operand1_type , 1
        je exco_memory_reg
            jmp memory_reg
        exco_memory_reg:

        parse_int operand1_more_info , 1
        mov bx , parsed_int_value
        execute_instruction1_operand memory_values , 8
        jmp finish
    memory_reg:
        cmp operand1_type , 5
        
        je exco_reg_8
            jmp reg_8
        exco_reg_8:

        mov bh , 0
        mov bl , operand1_more_info
        mov si , bx
        add si , bx
        mov bx , registers_values[si]
        execute_instruction1_operand memory_values , 8
        jmp finish
    reg_8:
        cmp operand1_type , 4
        je exco_reg_16
            jmp reg_16
        exco_reg_16:

        mov bl , operand1_more_info
        mov bh , 0
        sub bx , 8
        execute_instruction1_operand registers_values , 8
        jmp finish
    reg_16:
        cmp operand1_type , 3
        mov bh , 0
        mov bl , operand1_more_info
        mov si , bx
        add si , bx
        mov bx , si
        execute_instruction1_operand registers_values , 16
        jmp finish
   finish:                   
endm execute_command_1_operand

check8_or_16 macro
    local size_8 , size_16, finish
    cmp operand2_type , 4
    je size_8
    cmp operand2_type , 3
    je size_16
    cmp operand2_type , 2
    ;; if not unexpected error
        cmp operand2_more_info , 2
        jle size_8
        jmp size_16
    size_8:
    mov dl , 0
    jmp finish
    size_16:
    mov dl , 1
    finish:
endm check8_or_16

execute_command macro
    local memory_value , memory_reg , reg_8 , reg_16 , finish , size_16 , size_16_2 , memory_exc1 , size_16_exc2 , reg_8_exc2 , reg_16_exc3
    local size_16_2_exc2
    ; if register
    value_from_operand2
    mov ax , operand2_value
    
    memory_value:
        cmp operand1_type , 1
        je memory_exc1
            jmp memory_reg
        memory_exc1:
        parse_int operand1_more_info , 1
        mov bh , 0
        mov bx , parsed_int_value
        check8_or_16
        cmp dl , 0
        je size_16_exc2
            jmp size_16
        size_16_exc2:
        ;;;;;;;;;;;;;;;;
        execute_instruction memory_values[0] ,  8
        jmp finish
        size_16:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;
        execute_instruction memory_values[0] , 16
        jmp finish
    memory_reg:
        cmp operand1_type , 5
        je reg_8_exc2
            jmp reg_8
        reg_8_exc2:
        mov bh , 0
        mov bl , operand1_more_info
        mov si , bx
        add si , bx
        mov bx , registers_values[si]
        check8_or_16
        cmp dl , 0
        je size_16_2_exc2
            jmp size_16_2
        size_16_2_exc2:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;mov memory_values[bx] , al
        execute_instruction memory_values[0] ,  8
        jmp finish
        size_16_2:
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;mov word ptr memory_values[bx] , ax
        execute_instruction memory_values[0] ,  16
        jmp finish
    reg_8:
        cmp operand1_type , 4 
        je reg_16_exc3
            jmp reg_16
        reg_16_exc3:
        mov bl , operand1_more_info
        mov bh , 0
        sub bx , 8
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       ; mov byte ptr registers_values[bx] , al
        execute_instruction registers_values[0] , 8
        jmp finish
    reg_16:
        cmp operand1_type , 3
        ;; if not equal unexpected error
        mov bh , 0
        mov bl , operand1_more_info
        mov si , bx
        add si , bx
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;mov registers_values[si] , ax
        mov bx , si
        
        execute_instruction registers_values[0] , 16
        jmp finish
    
    finish:
endm execute_command

value_from_operand2 macro
    local memory_value , memory_reg , reg_8 , reg_8_odd , reg_8_even , reg_16 , value , finish 
    memory_value:
        cmp operand2_type , 1
        jne memory_reg
        parse_int operand2_more_info , 1
        mov bx , parsed_int_value
        mov bx , word ptr memory_values[bx]
        mov operand2_value , bx
        jmp finish
    memory_reg:
        cmp operand2_type , 5
        jne reg_8
        mov bh , 0
        mov bl , operand2_more_info 
        mov si , bx
        add si , bx
        mov bx , registers_values[si]
        mov bx , word ptr memory_values[bx]
        mov operand2_value , bx
        jmp finish
    reg_8:
        cmp operand2_type , 4
        jne reg_16
        mov bh , 0
        mov bl , operand2_more_info
        sub bx , 8
        mov bl , byte ptr registers_values[bx]
        mov operand2_value , bx
        jmp finish
    reg_16:
        cmp operand2_type , 3
        jne value
        mov bh , 0
        mov bl , operand2_more_info 
        mov si , bx
        add si , bx
        mov bx , registers_values[si]
        mov operand2_value , bx
        jmp finish
    value:
        cmp operand2_type , 2 
        ;  if false unexpected error
        parse_int input_operand2[2] , input_operand2[1]
        mov bx , parsed_int_value
        mov operand2_value , bx

    finish:
ENDM VALUE_FROM_OPERAND2

execute_instruction1_operand macro arr , size 
    local inc_inst , dec_inst , div_inst , mul_inst , finish , inc_size_16 , dec_size_16 , mul_size_16 , div_size_16 , before_div , before_mul
    pushNew
    mov cl , 8
    inc_inst:
        cmp counter_for_game_validation1 , 12
        jne dec_inst
        cmp cl , size
        jne inc_size_16
        inc byte ptr arr[bx]
        jmp finish
        inc_size_16:
        inc word ptr arr[bx]
        jmp finish
    dec_inst:
        cmp counter_for_game_validation1 , 13
        jne div_inst
        cmp cl ,size
        jne dec_size_16
        dec byte ptr arr[bx]
        jmp finish
        dec_size_16:
        dec word ptr arr[bx]
        jmp finish
    div_inst:
        cmp counter_for_game_validation1 , 14
        jne mul_inst
        mov dx , registers_values[6]
        mov ax , registers_values[0]
        cmp cl , size
        
        jne div_size_16
        div byte ptr arr[bx]
        jmp before_div
        div_size_16:
        div word ptr arr[bx]
        before_div:
        mov registers_values[6] , dx
        mov registers_values[0] , ax
        jmp finish
    mul_inst:
        cmp counter_for_game_validation1 , 15
        mov dx , registers_values[6]
        mov ax , registers_values[0]
        cmp cl , size
        jne mul_size_16
        mul byte ptr arr[bx]
        jmp before_mul
        mul_size_16:
        mul word ptr arr[bx]
        before_mul:
        mov registers_values[6] , dx
        mov registers_values[0] , ax
        jmp finish 
    finish:
    popNew
endm execute_instruction1_operand

execute_instruction macro arr , size
    local inst_mov , inst_add , inst_adc , inst_sbb , inst_xor , inst_sub , inst_and , and_16 , xor_16 , mov_16 , add_16 , sub_16 , adc_16 , sbb_16 , finish
    local inst_ror , inst_rol , inst_shl , inst_shr , inst_rcr , ror_16 , rol_16 , shl_16 , rcr_16 , shr_16
    pushNew
    
    mov dl , 8
    inst_mov:
        cmp counter_for_game_validation1 , 0
        jne inst_add
        cmp dl , size
        jne mov_16
        mov byte ptr arr[bx] , al
        jmp finish
        mov_16:
        mov word ptr arr[bx] , ax
        jmp finish
    inst_add:
        cmp counter_for_game_validation1 , 1
        jne inst_sub
        cmp dl , size
        jne add_16
        add byte ptr arr[bx] , al
        jmp finish
        add_16:
        add word ptr arr[bx] , ax
        jmp finish
    
    inst_sub:
        cmp counter_for_game_validation1 , 2
        jne inst_adc
        cmp dl , size
        jne sub_16
        sub byte ptr arr[bx] , al
        jmp finish
        sub_16:
        sub word ptr arr[bx] , ax
        jmp finish
    inst_adc:
        cmp counter_for_game_validation1 , 3
        jne inst_sbb
        cmp dl , size
        jne adc_16
        adc byte ptr arr[bx] , al
        jmp finish
        adc_16:
        adc word ptr arr[bx] , ax
        jmp finish
    
    inst_sbb:         
        cmp counter_for_game_validation1 , 4
        jne inst_and
        cmp dl , size
        jne sbb_16
        sbb byte ptr arr[bx] , al
        jmp finish
        sbb_16:
        sbb word ptr arr[bx] , ax
        jmp finish
    
    inst_and:
        cmp counter_for_game_validation1 , 5
        jne inst_xor
        cmp dl , size
        jne and_16
        and byte ptr arr[bx] , al
        jmp finish
        and_16:
        and word ptr arr[bx] , ax
        jmp finish
    
    inst_xor:
        cmp counter_for_game_validation1 , 6
        jne inst_rol
        cmp dl , size
        jne xor_16
        xor byte ptr arr[bx] , al
        jmp finish
        xor_16:
        xor word ptr arr[bx] , ax
        jmp finish
    ; add validation
    inst_rol:
        mov cl , al 
        cmp counter_for_game_validation1 , 7
        jne inst_ror
        cmp dl , size
        
        jne rol_16

        rol byte ptr arr[bx] , cl
        jmp finish
        rol_16:
        rol word ptr arr[bx] , cl
        jmp finish
    inst_ror:
        cmp counter_for_game_validation1 , 8
        jne inst_rcr
        cmp dl , size
        jne ror_16
        ror byte ptr arr[bx] , cl
        jmp finish
        ror_16:
        ror word ptr arr[bx] , cl
        jmp finish
    inst_rcr:
        cmp counter_for_game_validation1 , 9
        jne inst_shr
        cmp dl , size
        jne rcr_16
        rcr byte ptr arr[bx] , cl
        jmp finish
        rcr_16:
        rcr word ptr arr[bx] , cl
        jmp finish
    inst_shr:
        cmp counter_for_game_validation1 , 10
        jne inst_shl
        cmp dl , size
        jne shr_16
        shr byte ptr arr[bx] , cl
        jmp finish
        shr_16:
        shr word ptr arr[bx] , cl
        jmp finish 
    inst_shl:
        cmp counter_for_game_validation1 , 11
        cmp dl , size
        jne shl_16
        shl byte ptr arr[bx] , cl
        jmp finish
        shl_16:
        shl word ptr arr[bx] , cl
        jmp finish                        

    finish:
    popNew
endm execute_instruction

parse_int MACRO value , size 
    local parse_int_loop , norm , not_norm
    pushNew 
    mov parsed_int_value , 0
    mov bh , 0
    mov bl , size 

    mov si , bx 
    dec si 
    mov cx , bx 
     
    mov bx , 1 
    parse_int_loop: 
    mov ah , 0 
    mov al , value[si] 
     
    cmp ax , 97 
    jl norm 
    sub ax , 87    
    jmp not_norm 
    norm:     
    sub ax , 48 
    not_norm: 
    mul bx 
     
    add parsed_int_value , ax 
    mov ax , bx 
    mov bx , 10h 
    mul bx 
    mov bx , ax 
 
    dec si 
    dec cx 
    jnz parse_int_loop 
    popNew     
ENDM parse_int

pushNew MACRO params
    push ax
    push bx
    push cx
    push dx
    push si
    push di
ENDM pushNew

popNew MACRO params
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
ENDM popNew

printString macro message
    mov ah , 9
    lea dx , message
    int 21h
endm printString

printDigit macro
    local not_char
    pushNew
    mov ah , 2
    cmp dl , 10
    jl not_char
        add dl , 39
    not_char:
    add dl , 48
    int 21h
    popNew
endm printDigit

printString2 macro num
    pushNew    
        mov al , num
        mov ah , 0
        mov bl , 10h
        div bl
        
        mov bh , al
        mov bl , ah 
        
        mov dl, bh
        printDigit
        
        mov dl, bl
        printDigit
    popNew    
endM printString2

printString4 macro num
    pushNew
        mov ax , num
        mov dx , 0
        mov cx , 100h
        div cx
        printString2 al
        printString2 dl
    popNew
endm printString4

moveCursor macro x , y
    mov ah , 2
    mov bh , 0
    mov dl , x
    mov dh , y
    int 10h
endm moveCursor

.model large
.Stack 64
.data
	bbb                               db 0
	                                  db 20 dup("$")
	squareWH                          dw 15
	square2WH                         dw 15
	squareWHB                         db 15
	counter                           db 0
	finishLoop1                       dw 0
	finishLoop2                       dw 0
	squareColors                      db 1800 dup(100)
	squaresNum                        dw 0
	targetColors                      db 16 dup(3)
	gunPos                            dw 0
	shotPos                           dw ?
	gunShoted                         db 0
	shotXPos                          dw 0
	shotYPos                          dw 0
	pixelColorBeforeShot              db 0
	targetShoted                      dw 8 dup(0)
	shotedNow                         db 0
	arrXPos                           dw 30 dup("$")
	arrYPos                           dw 30 dup("$")
	arrPixels                         db 300 dup("$")
	rand                              dw 0
	squareXInc                        dw 8 dup(0)
	squareYInc                        dw 8 dup(0)
	xPosTemp                          dw 0
	yPosTemp                          dw 0
	squareX                           dw 8 dup(400)
	squareY                           dw 8 dup(400)

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	temp_draw_positions               db 10 dup("$")
	; ///////////////////////////////////////////////////////////////////////
	invalid_char_sentance1            db "enter the invalid char, Please " , 20 dup('$')
	invalid_char_read                 db 3 , ? , 20 dup('$')

	winner_player_sen                 db "YOU ARE THE WINNER" , 20 dup('$')
	looser_player_sen                 db "YOU LOOSE" , 20 dup('$')
	is_data_sent                      db 0
	is_data_recieved                  db 0
	is_data_sent2                     db 0
	is_data_recieved2                 db 0

	sentance_1                        db "THINK TWICE" , 20 dup('$')
	sentance_2                        db "CODE ONCE" , 20 dup('$')
	is_invalid_power                  db 0
	is_invalid_power2                 db 0
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	level                             db 1

	forbidden_char_sen                db "FC " , 20 dup('$')
	invalid_syntax_or_norm            db 0
	is_invalid                        db 0
	type_executing                    db 0                                                                                                                           	;; 0 => opponent processor ;; 1 => my Processor ;; 2 => my and opponent
	initial_points                    dw 110h
	initial_points_op                 dw 110h
	turn                              db 0                                                                                                                           	;; 1 => your turn           0 => opponent turn
	clear_all_reg_power               db 1
	position_after_clear              db 1 , 19
	;;;;;;;;;;;;;;;;;;;;;;;;; validation things
	commands                          db "mov" , "add" ,"sub" , "adc" , "sbb" , "and" , "xor" , "rol" , "ror" , "rcr" ,"shr" , "shl" , "inc" , "dec"  , "div" , "mul"
	memoryAddresses                   db 16 dup(0)
	counter_for_game_validation1      dw 0
	input_command1                    db 4, ? , 5 dup("$")
	                                  db 20 dup("$")                                                                                                                 	;;;; don't remove it
	invalid_char1                     db "i"
	                                  db 20 dup("$")                                                                                                                 	;;;; don't remove it
	invalid_char_op                   db "a"
	invalid_char_temp                 db "j"
	                                  db 20 dup("$")                                                                                                                 	;;;; don't remove it

	input_operand1                    db 20 , 0 , 20 dup("$")
	                                  db 20 dup("$")
	input_operand2                    db 20 , 0 , 20 dup("$")
	input_string                      db 30 , ? , 30 dup("$")
	input_string_counter              db 0
	hexa                              db 0
	registers                         db "ax" , "bx" , "cx" , "dx" , "si" , "di" , "sp" , "bp" , "al" , "ah" , "bl" , "bh" , "cl" , "ch" , "dl" , "dh"
	                                  db 20 dup("?")
	registers_values                  dw 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0
	                                  db 20 dup("$")
	memory_values                     db 16 dup(0)
	carry_flag                        db 0
	operand1_type                     db ?
	operand2_type                     db ?
	operand1_more_info                db ?
	operand2_more_info                db ?
	valid_instruction                 db ?
	valid_operands                    db ?
	register_type                     db ?
	dummy_string                      db 5 , '12345'
	valid_input                       db 'valid$'
	invalid_input                     db 'invalid$'
	has_operand                       db 0
	operand2_value                    dw 0
	parsed_int_value                  dw 0
	registers_values_op               dw 8 dup(0)
	                                  db 20 dup("$")
	memory_values_op                  db 16 dup(0)
	                                  db 20 dup("$")
	registers_temp                    dw 8 dup(40)
	                                  db 20 dup("$")
	memory_temp                       db 16 dup(30)
	                                  db 20 dup("$")
	clear_input_position              db 17 dup(" ") , '$'
	clear_inline_position             db 30 dup(" ") , '$'
	mem                               db 50 , ? , 50 dup("$")
	registers_names                   db "AX $BX $CX $DX $SI $DI $SP $BP $"
	nameTemp                          db "ahmed aref$"
	messageTemp                       db "0000$"
	memoryTemp                        db "00$"
	pointsTemp                        db "000$"
	level_op                          db ?

	nameString                        db 'Enter your name : $'
	userName                          db 30 , ? , 30 dup("$")
	userName_op                       db 30 , ? , 30 dup("$")
	initialPointsString               db 'inital points : $'
	initialPoints                     db 4 , ? , 4 dup("$")
	levelString                       db 'Enter the level you want: $'
	level_temp                        db 3 , ? , 10 dup("$")
	regInValue                        db 5 , ? , 5 dup("$")
	temp_reg1                         db ?
	temp_reg2                         db ?
	end_game_time                     dw 100h
	bird_game_start_time              dw 100h
	is_bird_game_running              db 0
	start_timer                       db 0
	invitatian_sender                 db 0
	mode_of_working                   db 0
	inline_message                    db 70 , ? , 100 dup("$")
	inline_message_op                 db 70 , ? , 100 dup("$")
	my_location_in_inline_chat        db 1 , 21
	timer_temp_5                      dw 0
	NOT_A_VALID_NAME_MESSAGE          db "Not a valid name$"
	NOT_A_VALID_POINTS_MESSAGE        db "Not a valid points$"
	enter_your_name_message           db "Please enter your name",10,13,"$"
	enter_your_initial_points_message db "Initial points",10,13,"$"
	initial_points_of_the_player      db 4 , ? , 10 dup('$')
	initial_Position_start_x          db 3
	initial_points_real               dw 0
	initial_points_real_op            dw 0
    
	choose_game_message_invitian      db " want's to start the game$"
	choose_chatting_message_invitian  db " want's to start chatting$"
	choose_chatting_message           db "To start chatting press F1$"
	choose_game_message               db "To start the game press F2$"
	choose_closing_message            db "To end the program press ESC$"
    
	line                              db 80 dup("_") , 20 dup('$')
	message                           db 70 , ? , 100 dup("$")
	message_recieved                  db 70 , ? , 100 dup("$")
	my_location                       db 0
	friend_location                   db 12
	my_location_in_line               db 0 , 0

	accepted_from_me_chat             db 0
	accepted_from_other_chat          db 0
    
	accepted_from_me_game             db 0
    accepted_from_other_game db 0
.CODE
chat_control_recieve_position PROC
	                              cmp                        friend_location , 21
	                              jl                         no_scroll_required
	                              scrollOneLine              0C00H , 154fH
	                              moveCursor                 0 , friend_location
	                              jmp                        finish_scrolling_func
	no_scroll_required:           
	                              moveCursor                 0 , friend_location
	                              inc                        friend_location
	finish_scrolling_func:        
	                              mov                        ch , 0
	                              mov                        cl , message_recieved[1]
	                              mov                        si , 2
	ccrp_ex_loop:                 
	                              mov                        ah,2
	                              mov                        dl,message_recieved[si]
	                              int                        21h
	                              inc                        si
	                              dec                        cx
	                              jnz                        ccrp_ex_loop
	ccrp_finish:                  
	                              moveCursor                 my_location_in_line[0] , my_location
	                              ret
chat_control_recieve_position ENDP

chatting_Module macro
	                              mov                        my_location , 0
	                              mov                        friend_location , 12
	                              mov                        message[1] , 0
	                              changeMode                 3
	                              printLn                    11
	                              printLn                    22
	                              moveCursor                 0 , 0
	chat_loop:                    
	                              chat_read_dynamic
	                              chat_recieve_communicate
	                              jmp                        chat_loop
	                              endm                       chatting_Module

handle_notification proc
	                              cmp                        accepted_from_other_chat , 1
	                              jne                        not_accepted_chat_yet
	;;;;;;;;;;;;;;;;;;;;;;; now i accept the invitation so i am not the controller
	                              send_byte                  "a"
	                              mov                        dx , 1
	                              ret
	not_accepted_chat_yet:        
	                              send_byte                  "i"
	                              mov                        dx , 0
	                              ret
handle_notification endp

handle_notification2 proc
	                              cmp                        accepted_from_other_game , 1
	                              jne                        not_accepted_game_yet
	                              mov                        invitatian_sender , 0
	                              send_byte                  "m"
	                              mov                        dx , 1
	                              ret
	not_accepted_game_yet:        
	                              send_byte                  "n"
	                              mov                        dx , 0
	                              ret
handle_notification2 endp
exchange_invalid_char PROC
	                              mov                        al , invalid_char1
	                              mov                        ah , invalid_char_op
	                              mov                        invalid_char_op , al
	                              mov                        invalid_char1 , ah
	                              ret
exchange_invalid_char endp

seperate_input_string PROC
	                              mov                        bx , 2
	                              mov                        si , 2
	                              mov                        dl , invalid_char1
	                              add                        input_string[1] , 2
	sep_instruction_loop:         
	                              cmp                        si , 5
	                              je                         sep_end_instruction_loop
	                              cmp                        bl , input_string[1]
	                              je                         sep_end_instruction_loop

	                              cmp                        input_string[bx] , dl                                                                                                  	;; forbidden char
	                              jne                        sep_invalid_path
	                              mov                        invalid_syntax_or_norm , 1
	                              jmp                        sep_invalid
	sep_invalid_path:             
	                              mov                        ah , input_string[bx]
	                              mov                        input_command1[si] , ah
	                              inc                        si
	sep_continue_instruction:     
	                              inc                        bx
	                              jmp                        sep_instruction_loop
	sep_end_instruction_loop:     
	                              mov                        si , 2
	sep_operand1_loop:            
	                              cmp                        bl , input_string[1]
	                              je                         sep_end_operand1_loop
	                              cmp                        input_string[bx] , dl                                                                                                  	;; forbidden char
	                              jne                        sep_invalid_path_23
	                              mov                        invalid_syntax_or_norm , 1
	                              jmp                        sep_invalid
	sep_invalid_path_23:          
	                              cmp                        input_string[bx] , ','
	                              je                         sep_end_operand1_loop
	                              cmp                        input_string[bx] , ' '
	                              je                         sep_continue_operand1
	                              mov                        ah , input_string[bx]
	                              mov                        input_operand1[si] , ah
	                              inc                        si
	sep_continue_operand1:        
	                              inc                        bx
	                              jmp                        sep_operand1_loop
	sep_end_operand1_loop:        
	                              mov                        cx , si
	                              sub                        cl , 2
	                              mov                        input_operand1[1] , cl
	                              mov                        si , 2
	                              cmp                        input_string[bx] , ','
	                              jne                        sep_operand2_loop
	                              inc                        bx
	sep_operand2_loop:            
	                              cmp                        bl , input_string[1]
	                              je                         sep_end_operand2_loop
	                              cmp                        input_string[bx] , dl
	                              jne                        sep_invalid_path_24
	                              mov                        invalid_syntax_or_norm , 1
	                              jmp                        sep_invalid
	sep_invalid_path_24:          
	                              cmp                        input_string[bx] , ' '
	                              je                         sep_continue_operand2
	                              mov                        ah , input_string[bx]
	                              mov                        input_operand2[si] , ah
	                              inc                        si
	sep_continue_operand2:        
	                              inc                        bx
	                              jmp                        sep_operand2_loop
	sep_end_operand2_loop:        
    
	                              mov                        cx , si
	                              sub                        cl , 2
	                              mov                        input_operand2[1] , cl
	                              mov                        valid_operands , 1
	                              jmp                        sep_finish
	sep_invalid:                  
	                              mov                        valid_operands, 0
	sep_finish:                   
	                              ret
seperate_input_string endp

get_the_valid_command proc
	                              mov                        cx ,16
	                              mov                        counter_for_game_validation1 , 0
	my_Loop_for_game_validation:  
	                              mov                        SI , counter_for_game_validation1
	                              compareString              input_command1[2] , commands[si]
	                              cmp                        dx , 1
	                              je                         command_exist_in_arr
	                              add                        counter_for_game_validation1 , 3
	                              dec                        cx
	                              jnz                        my_Loop_for_game_validation
	command_exist_in_arr:         
	                              ret
get_the_valid_command endp

drawPositions PROC
	                              moveCursor                 4,3
	                              printString                registers_names[0]
	                              printString4               registers_values[0]
	                              moveCursor                 4,5
	                              printString                registers_names[4]
	                              printString4               registers_values[2]
	                              moveCursor                 4,7
	                              printString                registers_names[8]
	                              printString4               registers_values[4]
	                              moveCursor                 4,9
	                              printString                registers_names[12]
	                              printString4               registers_values[6]
		
	                              moveCursor                 12,3
	                              printString                registers_names[16]
	                              printString4               registers_values[8]
	                              moveCursor                 12,5
	                              printString                registers_names[20]
	                              printString4               registers_values[10]
	                              moveCursor                 12,7
	                              printString                registers_names[24]
	                              printString4               registers_values[12]
	                              moveCursor                 12,9
	                              printString                registers_names[28]
	                              printString4               registers_values[14]
	;;;;;;;;;;;;;;;;;;;
	                              moveCursor                 22,3
	                              printString                registers_names[0]
	                              printString4               registers_values_op[0]
	                              moveCursor                 22,5
	                              printString                registers_names[4]
	                              printString4               registers_values_op[2]
	                              moveCursor                 22,7
	                              printString                registers_names[8]
	                              printString4               registers_values_op[4]
	                              moveCursor                 22,9
	                              printString                registers_names[12]
	                              printString4               registers_values_op[6]

	                              moveCursor                 30,3
	                              printString                registers_names[16]
	                              printString4               registers_values_op[8]
	                              moveCursor                 30,5
	                              printString                registers_names[20]
	                              printString4               registers_values_op[10]
	                              moveCursor                 30,7
	                              printString                registers_names[24]
	                              printString4               registers_values_op[12]
	                              moveCursor                 30,9
	                              printString                registers_names[28]
	                              printString4               registers_values_op[14]
	;;;;;;;;;;;;;;;;;;;
	                              mov                        temp_draw_positions[0] , 0
	                              mov                        cx , 16
	drawPositions_loop2:          
	                              moveCursor                 0 , temp_draw_positions[0]
	                              mov                        bl , temp_draw_positions[0]
	                              mov                        bh , 0
	                              printString2               memory_values[bx]
	                              inc                        temp_draw_positions[0]
	                              dec                        cx
	                              jnz                        drawPositions_loop2
    
	                              mov                        temp_draw_positions[0] , 0
	                              mov                        cx , 16
	drawPositions_loop2_op:       
	                              moveCursor                 38 , temp_draw_positions[0]
	                              mov                        bl , temp_draw_positions[0]
	                              mov                        bh , 0
	                              printString2               memory_values_op[bx]
	                              inc                        temp_draw_positions[0]
	                              dec                        cx
	                              jnz                        drawPositions_loop2_op
	;;;;;;;;;;;;;;;;;;;;;;;;
	                              moveCursor                 15 , 16
	                              printString4               initial_points

	                              moveCursor                 21 , 16
	                              printString4               initial_points_op
	;;;;;;;;;;;;;;;;;;;;;;;;
	                              moveCursor                 4 , 11
	                              print_t_size               userName
	                              moveCursor                 22 , 11
	                              print_t_size               userName_op

	                              cmp                        level , 2
	                              je                         level2_dont_show
	                              moveCursor                 15 , 14
	                              printString                forbidden_char_sen
	                              display_char               invalid_char1
	                              moveCursor                 21 , 14
	                              printString                forbidden_char_sen
	                              display_char               invalid_char_op
	level2_dont_show:             
	                              ret
drawPositions endp

put_in_temp proc
	                              mov                        cx , 8
	                              mov                        si , 0
	pit1_myLoop:                  
	                              mov                        ax , registers_values[si]
	                              mov                        registers_temp[si] , ax
	                              mov                        ax , registers_values_op[si]
	                              mov                        registers_values[si] , ax
	                              add                        si , 2
	                              dec                        cx
	                              jnz                        pit1_myLoop
	                              mov                        cx , 16
	                              mov                        si , 0
	pit2_myLoop:                  
	                              mov                        al , memory_values[si]
	                              mov                        memory_temp[si] , al
	                              mov                        al , memory_values_op[si]
	                              mov                        memory_values[si] , al
	                              inc                        si
	                              dec                        cx
	                              jnz                        pit2_myLoop
	                              ret
put_in_temp endp

back_to_normal proc
	                              mov                        cx , 8
	                              mov                        si , 0
	bto1_myLoop:                  
	                              mov                        ax , registers_values[si]
	                              mov                        registers_values_op[si] , ax
	                              mov                        ax , registers_temp[si]
	                              mov                        registers_values[si] , ax
	                              add                        si , 2
	                              dec                        cx
	                              jnz                        bto1_myLoop
	                              mov                        cx , 16
	                              mov                        si , 0
	bto2_myLoop:                  
	                              mov                        al , memory_values[si]
	                              mov                        memory_values_op[si] , al
	                              mov                        al , memory_temp[si]
	                              mov                        memory_values[si] , al
	                              inc                        si
	                              dec                        cx
	                              jnz                        bto2_myLoop
	                              ret
back_to_normal endp

execute_command_final proc                                                                                                                                                      		;;; must be a procedure
	                              mov                        invalid_syntax_or_norm , 0
	                              mov                        is_invalid , 0
	                              call                       seperate_input_string
	                              call                       get_the_valid_command

	                              cmp                        cx , 0
	                              jne                        exf_main_invalid1
	                              jmp                        exf_invalid
	exf_main_invalid1:            
	                              mov                        ax , counter_for_game_validation1
	                              mov                        cx , 3
	                              div                        cl
	                              mov                        counter_for_game_validation1 , ax
	                              cmp                        valid_operands , 0

	                              jne                        exf_main_invalid2
	                              jmp                        exf_invalid
	exf_main_invalid2:            
	                              VALIDATE_SINGLE_OPERAND    INPUT_OPERAND1[1]                                                                                                      	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                              cmp                        al , 0
	; syntax
	                              jne                        exf_main_invalid3
	                              jmp                        exf_invalid
	exf_main_invalid3:            

	                              MOV                        OPERAND1_TYPE , AL
	                              MOV                        OPERAND1_MORE_INFO , AH
	                              VALIDATE_SINGLE_OPERAND    INPUT_OPERAND2[1]                                                                                                      	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	                              cmp                        al , 0
	;syntax
	                              jne                        exf_main_invalid4
	                              jmp                        exf_invalid
	exf_main_invalid4:            
    
	                              cmp                        counter_for_game_validation1 , 12
	                              jge                        exf_one_operand
	                              cmp                        has_operand , 0

	                              jne                        exf_main_invalid5
	                              jmp                        exf_invalid
	exf_main_invalid5:            
    
	                              jmp                        exf_true_operands_count
	exf_one_operand:              
	                              cmp                        has_operand , 1

	                              jne                        exf_main_invalid6
	                              jmp                        exf_invalid
	exf_main_invalid6:            

	                              jmp                        exf_true_operands_count2
	exf_true_operands_count:      
	                              MOV                        OPERAND2_TYPE , AL
	                              MOV                        OPERAND2_MORE_INFO , AH
	exf_true_operands_count2:     
	                              LAST_VALIDATION                                                                                                                                   	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                              cmp                        valid_operands , 0
	                              jne                        exf_main_invalid7
	                              jmp                        exf_invalid
	exf_main_invalid7:            
    
	                              cmp                        counter_for_game_validation1 , 12
	                              jl                         exf_main_ex_com2
	                              jmp                        exf_ex_com2
	exf_main_ex_com2:             
	                              execute_command                                                                                                                                   	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                              jmp                        exf_finish_main
	exf_ex_com2:                  
	                              execute_command_1_operand                                                                                                                         	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	                              jmp                        exf_finish_main
	exf_invalid:                  
	;;;; invalid
	                              mov                        is_invalid , 1
	exf_finish_main:              
	                              sub                        input_string[1] , 2
	                              mov                        input_operand1[1] , 0
	                              mov                        input_operand2[1] , 0
	                              mov                        operand1_type , 20
	                              mov                        operand2_type , 20
	;drawPositions
	                              ret
execute_command_final ENDP

check_power_up PROC
	                              mov                        dx , 1
	                              cmp                        ah , 43h
	                              jne                        not_f9
	                              cmp                        is_invalid_power , 1
	                              jne                        ok_to_ex_forbidden
	                              ret
	ok_to_ex_forbidden:           
	                              clear_buffer
	CHECK_power_loop:             mov                        ah,1
	                              int                        16h
	                              jz                         CHECK_power_loop
	                              mov                        cl , al
	                              send_byte                  "f"
	                              send_byte                  cl
	                              sub                        initial_points , 8
	                              mov                        invalid_char_op , cl
	                              mov                        is_invalid_power , 1
	                              call                       drawPositions
	                              mov                        dx , 1
	                              ret
	not_f9:                       
	                              cmp                        ah , 40h                                                                                                               	;;;;;;;;;;;;;;;; scan code f6 ;;; own processor
	                              jne                        f7
	                              mov                        type_executing , 1                                                                                                     	;; my processor
	                              cmp                        level , 2
    
	                              ret
	f7:                           
	                              cmp                        ah , 41h
	                              jne                        not_f7
	                              mov                        type_executing , 2                                                                                                     	;; both Processor
	                              cmp                        level , 2
	; sub initial_points , 3 ;; rule
	                              ret
	not_f7:                       
	                              cmp                        ah , 42h
	                              jne                        not_f8
	                              cmp                        clear_all_reg_power , 1
	                              jne                        return_check_power
	; sub initial_points , 30
	                              mov                        dx , 1
	                              mov                        clear_all_reg_power , 2
	return_check_power:           
	                              ret
	not_f8:                       
	                              mov                        dx , 0
	                              ret
check_power_up ENDP

sendCommand PROC
	                              send_byte                  0                                                                                                                      	;;;;;; normal case
	                              send_byte                  input_string[1]
	                              mov                        cl , input_string[1]
	                              mov                        si , 2
	send_loop:                    
	                              send_byte                  input_string[si]
	                              inc                        si
	                              dec                        cl
	                              jnz                        send_loop
	                              ret
sendCommand ENDP

recieve_command PROC
	                              recieve_byte
	                              mov                        cl , al
	                              mov                        input_string[1] , al
	                              mov                        si , 2
	recieve_loop:                 
	                              recieve_byte
	                              mov                        input_string[si] , al
	                              inc                        si
	                              dec                        cl
	                              jnz                        recieve_loop
	                              ret
recieve_command ENDP

remove_char_command PROC
	                              display_char               8
	                              display_char               32                                                                                                                     	;just cleaning the deleted char place
	                              display_char               8
	                              ret
remove_char_command ENDP

	;description
control_input_position PROC
	                              cmp                        input_string[1] , 0
	                              jne                        cip_not_start
	                              moveCursor                 1 , 19
	                              printString                clear_input_position
	                              moveCursor                 1 , 19
	cip_not_start:                
	                              ret
control_input_position ENDP

control_recieve_position PROC
	                              moveCursor                 21 , 19
	                              printString                clear_input_position
	                              moveCursor                 21 , 19
	;;;;;;;;;;;;;;;;;;;;; printing
	                              mov                        ch , 0
	                              mov                        cl , input_string[1]
	;;;;;;;;;;;;;;;; if the size of the command == 0
	                              cmp                        cl , 0
	                              je                         crp_finish
	;;;;;;;;;;;;;;;;
	                              mov                        si , 2
	crp_ex_loop:                  
	                              mov                        ah,2
	                              mov                        dl,input_string[si]
	                              int                        21h
	                              inc                        si
	                              dec                        cx
	                              jnz                        crp_ex_loop
	crp_finish:                   
	                              ret
control_recieve_position ENDP
main_game MACRO
	                              local                      player_one_level , throw_main_path12 , tr_not_level2_read_reg , tr_reg_path_main , infiniteLoop , not_my_responsibility
	                              initialize_game_vars
	                              initialScreen
	                              sub                        level_temp[2] , "0"
	                              mov                        ah , level_temp[2]
	                              mov                        level , ah
    
	                              both_finished              level , level_op

	                              mov                        al , invalid_char1[0]
	                              mov                        invalid_char_op[0] , al
	                              both_finished              invalid_char_op[0] , invalid_char1[0]

	                              cmp                        invitatian_sender , 1
	                              jne                        not_me_the_inv_sen
	                              mov                        turn , 1
	                              jmp                        finish_me_the_inv_sen
	not_me_the_inv_sen:           
	                              mov                        turn , 0
	                              mov                        cl , level_op
	                              mov                        level , cl
	finish_me_the_inv_sen:        

	                              mov                        ax , initial_points_real
	                              mov                        bx , initial_points_real_op
	                              cmp                        ax , bx
	                              jnc                        player_one_level
	                              mov                        initial_points_op , ax
	                              jmp                        throw_main_path12
	player_one_level:             
	                              mov                        initial_points , bx
	throw_main_path12:            
    
	                              cmp                        level , 2
	                              je                         tr_not_level2_read_reg
	                              jmp                        not_level2_read_reg
	tr_not_level2_read_reg:       
	                              level2InitialScreen
	                              mov                        cx , 8
	                              mov                        si , 0
	reg_path_main:                
	                              mov                        ax , registers_values[si]
	                              mov                        registers_values_op[si] , ax
            
	                              mov                        al , byte ptr registers_values[si]
	                              mov                        temp_reg1 , al
	                              both_finished              temp_reg1 , temp_reg2
	                              mov                        al , temp_reg2
	                              mov                        byte ptr registers_values[si] , al
            
	                              mov                        al , byte ptr registers_values[si+1]
	                              mov                        temp_reg1 , al
	                              both_finished              temp_reg1 , temp_reg2
	                              mov                        al , temp_reg2
	                              mov                        byte ptr registers_values[si+1] , al

	                              add                        si , 2
	                              dec                        cx
	                              jz                         tr_reg_path_main
	                              jmp                        reg_path_main
	tr_reg_path_main:             
	not_level2_read_reg:          

	                              start_draw
	                              call                       drawPositions
	infiniteLoop:                 
	                              cmp                        is_bird_game_running , 0
	                              jne                        game_not_running_path
	                              jmp                        game_not_running
	game_not_running_path:        
	                              bird_game
	                              jmp                        infiniteLoop
	game_not_running:             
	                              cmp                        invitatian_sender , 1
	                              jne                        not_my_responsibility
	                              start_timer_of_two_dev
	not_my_responsibility:        
        
	                              control_mode_of_working

	                              get_the_winner
	                              power_clear_reg
	                              recieve_communicate
	                              cmp                        mode_of_working , 0
	                              je                         not_game_read_dynamic_path
	                              jmp                        not_game_read_dynamic
	not_game_read_dynamic_path:   
	                              game_read_dynamic          input_string
	                              jmp                        path_inline_chatting
	not_game_read_dynamic:        
	                              inline_chat_read_dynamic   inline_message
	path_inline_chatting:         
	                              jmp                        infiniteLoop
	end_main_finish:              
	                              endm                       main_game
MAIN PROC FAR
	                              mov                        ax, @data
	                              mov                        DS, ax

	                              conf
	                              StartModule
    
	start_of_choose_module:                                                                                                                                                         	;; string when going back
	                              changeMode                 03h
	                              mov                        accepted_from_me_chat , 0
	                              mov                        accepted_from_me_game , 0
	                              mov                        accepted_from_other_chat , 0
	                              mov                        accepted_from_other_game , 0
	                              clearBuffer
	                              clearScreen
	;;;;;;;;;;;;;;;;;;;; initialization of the data
	                              mov                        initial_Position_start_x , 5
	                              moveCursor                 10 , initial_Position_start_x
	                              printString                choose_chatting_message

	                              add                        initial_Position_start_x , 3
	                              moveCursor                 10 , initial_Position_start_x
	                              printString                choose_game_message
    
	                              add                        initial_Position_start_x , 3
	                              moveCursor                 10 , initial_Position_start_x
	                              printString                choose_closing_message

	BREAK_IF_CLICKED:             
	                              choose_recieve_communicate
	                              mov                        ah , 1
	                              int                        16h
	                              jnz                        BREAK_IF_CLICKED_path321
	                              jmp                        BREAK_IF_CLICKED
	BREAK_IF_CLICKED_path321:     

	                              cmp                        ah , 59
	                              jne                        CHOOSE_CHAT_MODE_path
	                              jmp                        CHOOSE_CHAT_MODE
	CHOOSE_CHAT_MODE_path:        
	                              cmp                        ah , 60
	                              jne                        CHOOSE_GAME_MODE_path
	                              jmp                        CHOOSE_GAME_MODE
	CHOOSE_GAME_MODE_path:        
	                              cmp                        ah , 1
	                              jne                        CHOOSE_END_PROGRAM_path
	                              jmp                        CHOOSE_END_PROGRAM
	CHOOSE_END_PROGRAM_path:      
    
	                              clearBuffer
	                              jmp                        BREAK_IF_CLICKED
    	
	CHOOSE_CHAT_MODE:             

	                              clearBuffer
	                              call                       handle_notification
	                              cmp                        dx , 0
	                              jne                        BREAK_IF_CLICKED_path
	                              jmp                        BREAK_IF_CLICKED
	BREAK_IF_CLICKED_path:        

	CHOOSE_CHAT_MODE_without_com: 
	                              clearBuffer
	                              chatting_Module
	                              jmp                        start_of_choose_module
    
	CHOOSE_GAME_MODE:             
	                              clearBuffer
	                              call                       handle_notification2
	                              cmp                        dx , 0
	                              jne                        BREAK_IF_CLICKED_path222
	                              jmp                        BREAK_IF_CLICKED
	BREAK_IF_CLICKED_path222:     

	CHOOSE_game_MODE_without_com: 
	                              clearBuffer
	                              main_game
	                              jmp                        start_of_choose_module
	CHOOSE_END_PROGRAM:           
	; close the program right and send a signal
	                              hlt
    MAIN ENDP
END MAIN