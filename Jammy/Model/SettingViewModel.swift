import Foundation

class SettingViewModel: ObservableObject {
    @Published var isModalActive = false
    var selectedSettingTitle: SettingTitleType = .other
    
    struct SettingTitle: Hashable, Identifiable {
        var id = UUID()
        var title : String
    }
    
    struct Setting: Identifiable {
        var id = UUID()
        var header: String
        var settingTitles: [SettingTitle]
    }
    
    var settings: [Setting] = [
        Setting(header: "ブックマーク",
                settingTitles: [SettingTitle(title: "編集")]),
        Setting(header: "その他",
                settingTitles: [SettingTitle(title: "プライバシーポリシー"),
                                SettingTitle(title: "ライセンス"),
                                SettingTitle(title: "バージョン")])
    ]
    
    enum SettingTitleType: String {
        case edit = "編集"
        case privacy = "プライバシーポリシー"
        case license = "ライセンス"
        case version = "バージョン"
        case other
    }
}
