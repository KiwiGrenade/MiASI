        DD y
        MOV A,#2
        MOV [y], A
        DD x
        MOV A,#3
        MOV [x], A
        MOV A,#4
        PUSH A
        MOV A,#4
        POP B
        CMP A, B
        JGE label_comp_2
        MOV A, #0
        JMP label_comp_end_2
        label_comp_2:
        MOV A, #1
        label_comp_end_2:
        PUSH A
        MOV A,#2
        PUSH A
        MOV A,#2
        POP B
        CMP A, B
        JNE label_comp_1
        MOV A, #0
        JMP label_comp_end_1
        label_comp_1:
        MOV A, #1
        label_comp_end_1:
        POP B
        AND A, B

    NOT A
    PUSH A
    MOV A,#2
    PUSH A
    MOV A, [x]
    POP B
    CMP A, B
    JG label_comp_0
    MOV A, #0
    JMP label_comp_end_0
    label_comp_0:
    MOV A, #1
    label_comp_end_0:
    POP B
    AND A, B
        JE label_else_0
                MOV A,#1
                MOV [y], A
        JMP label_if_end_0
    label_else_0:
                MOV A,#0
                MOV [y], A
    label_if_end_0:
        DD z
        MOV A,#3
        MOV [z], A
    MOV A,#3
    PUSH A
    MOV A, [z]
    POP B
    CMP A, B
    JE label_comp_3
    MOV A, #0
    JMP label_comp_end_3
    label_comp_3:
    MOV A, #1
    label_comp_end_3:
        JE label_else_1
                MOV A,#4
                MOV [z], A
            MOV A,#10
            PUSH A
            MOV A, [z]
            POP B
            CMP A, B
            JL label_comp_4
            MOV A, #0
            JMP label_comp_end_4
            label_comp_4:
            MOV A, #1
            label_comp_end_4:
                JE label_else_2
                        MOV A,#5
                        MOV [z], A
                JMP label_if_end_2
            label_else_2:
            label_if_end_2:
            MOV A,#5
            PUSH A
            MOV A, [z]
            POP B
            CMP A, B
            JLE label_comp_5
            MOV A, #0
            JMP label_comp_end_5
            label_comp_5:
            MOV A, #1
            label_comp_end_5:
                JE label_else_3
                        MOV A,#6
                        MOV [z], A
                JMP label_if_end_3
            label_else_3:
            label_if_end_3:
        JMP label_if_end_1
    label_else_1:
    label_if_end_1:

BRK