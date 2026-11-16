코드가 작동되게 하려면?

1. StarterGUI안의 자식들을 다음과 같이 설정하세요\n
    TimerUI (ScreenGUI)\n
       Status (TextLabel)\n
       TimerText (TextLabel)\n
       TimerUI (LocalScript) <-- TimerUI.luau\n
2. ServerScriptService\n
    RoundManager (Script)\n
