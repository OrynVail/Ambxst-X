.pragma library

var data = {
    "disks": ["/"],
    "updateServiceEnabled": true,
    "idle": {
        "general": {
            "lock_cmd": "flok lock",
            "before_sleep_cmd": "loginctl lock-session",
            "after_sleep_cmd": "flok screen on"
        },
        "listeners": [
            {
                "timeout": 150,
                "onTimeout": "flok brightness 10 -s",
                "onResume": "flok brightness -r"
            },
            {
                "timeout": 300,
                "onTimeout": "loginctl lock-session"
            },
            {
                "timeout": 330,
                "onTimeout": "flok screen off",
                "onResume": "flok screen on"
            },
            {
                "timeout": 1800,
                "onTimeout": "flok suspend"
            }
        ]
    },
    "ocr": {
        "eng": true,
        "spa": false,
        "lat": false,
        "jpn": false,
        "chi_sim": false,
        "chi_tra": false,
        "kor": false
    },
    "pomodoro": {
        "workTime": 1800,
        "restTime": 300,
        "autoStart": false,
        "syncSpotify": false
    }
}
