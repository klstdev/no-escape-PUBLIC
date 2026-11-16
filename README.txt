코드가 작동되게 하려면?

1. StarterGUI안의 자식들을 다음과 같이 설정하세요
    TimerUI (ScreenGUI)
       Status (TextLabel)
       TimerText (TextLabel)
       TimerUI (LocalScript) <-- TimerUI.luau
2. ServerScriptService
    RoundManager (Script)
