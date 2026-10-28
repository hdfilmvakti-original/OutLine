import SwiftUI
import AVFoundation

@main
struct OutLineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
// MARK: - Uygulama Dilleri ve Dil Yöneticisi
enum AppLanguage: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"
    
    var id: String { self.rawValue }
    
    var titleName: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }
}

class LanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage = .turkish
    
    func text(_ tr: String, _ en: String) -> String {
        return currentLanguage == .turkish ? tr : en
    }
}

// MARK: - Şarkı ve Çalma Listesi Modelleri
struct Song: Identifiable, Equatable {
    let id: String           // YouTube Video ID
    let title: String        // Şarkı Adı
    let artist: String       // Sanatçı / Kanal
    let duration: String     // Süre
    var localFileURL: URL?   // İndirilen yerel dosya yolu (Offline oynatma için)
}

struct Playlist: Identifiable {
    let id = UUID()
    var name: String
    var songs: [Song]
}

// MARK: - Ses Oynatıcı ve yt-dlp İndirme Yöneticisi
class MusicPlayerManager: ObservableObject {
    var player: AVPlayer?
    @Published var currentPlayingSong: Song?
    @Published var isPlaying = false
    
    @Published var downloadedSongs: [Song] = []
    @Published var playlists: [Playlist] = [
        Playlist(name: "Favorilerim", songs: []),
        Playlist(name: "Antrenman", songs: [])
    ]
    @Published var downloadingSongIDs: Set<String> = []
    
    // Şarkı Oynatma Fonksiyonu (İnternetten veya Offline Dosyadan)
    func playSong(_ song: Song) {
        currentPlayingSong = song
        
        let audioURL: URL?
        if let localURL = song.localFileURL {
            audioURL = localURL // İndirildiyse telefondan internetsiz çal
        } else {
            // yt-dlp veya YouTube akış simülasyon adresi
            audioURL = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3") 
        }
        
        guard let url = audioURL else { return }
        
        let playerItem = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        player?.play()
        isPlaying = true
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    // yt-dlp Destekli Gerçek İndirme Simülasyonu
    func downloadWithYtDlp(_ song: Song) {
        guard !downloadingSongIDs.contains(song.id) else { return }
        downloadingSongIDs.insert(song.id)
        
        // Gerçek uygulamada burada yt-dlp backend API'sine istek atılır ve .m4a indirilir
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent("\(song.id).m4a")
            
            var savedSong = song
            savedSong.localFileURL = destinationURL
            
            if !self.downloadedSongs.contains(where: { $0.id = song.id }) {
                self.downloadedSongs.append(savedSong)
            }
            self.downloadingSongIDs.remove(song.id)
        }
    }
    
    func isDownloaded(_ songID: String) -> Bool {
        return downloadedSongs.contains(where: { $0.id == songID })
    }
    
    func isDownloading(_ songID: String) -> Bool {
        return downloadingSongIDs.contains(songID)
    }
}

// MARK: - Ana Uygulama Arayüzü
struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var langManager = LanguageManager()
    @StateObject private var musicManager = MusicPlayerManager()
    
    let backgroundColor = Color(red: 0.12, green: 0.12, blue: 0.14)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundColor.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                SearchView(backgroundColor: backgroundColor)
                    .environmentObject(langManager)
                    .environmentObject(musicManager)
                    .tabItem {
                        Label(langManager.text("Keşfet", "Explore"), systemImage: "magnifyingglass")
                    }
                    .tag(0)
                
                LibraryView(backgroundColor: backgroundColor)
                    .environmentObject(langManager)
                    .environmentObject(musicManager)
                    .tabItem {
                        Label(langManager.text("Kütüphane", "Library"), systemImage: "music.note.list")
                    }
                    .tag(1)
                
                SettingsView(backgroundColor: backgroundColor)
                    .environmentObject(langManager)
                    .tabItem {
                        Label(langManager.text("Ayarlar", "Settings"), systemImage: "gearshape")
                    }
                    .tag(2)
            }
            .accentColor(.white)
            
            // Alt Müzik Çalar Çubuğu (Mini Player Bar)
            if let currentSong = musicManager.currentPlayingSong {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color(red: 0.22, green: 0.22, blue: 0.25))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentSong.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(currentSong.artist)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            musicManager.togglePlayPause()
                        }) {
                            Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 8)
                    }
                    .padding(12)
                    .background(Color(red: 0.18, green: 0.18, blue: 0.20))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 50) // Tab barın üstünde kalması için
                }
            }
        }
    }
}

// MARK: - 1. Keşfet ve Arama Ekranı
struct SearchView: View {
    let backgroundColor: Color
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var musicManager: MusicPlayerManager
    
    @State private var searchQuery = ""
    @State private var searchResults: [Song] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("OutLine")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField(langManager.text("YouTube'da müzik ara...", "Search music on YouTube..."), text: $searchQuery)
                            .foregroundColor(.white)
                            .onSubmit { performSearch() }
                        
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = ""; searchResults = [] }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(red: 0.18, green: 0.18, blue: 0.20))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    
                    if isLoading {
                        Spacer()
                        ProgressView().tint(.white).scaleEffect(1.3).frame(maxWidth: .infinity)
                        Spacer()
                    } else if searchResults.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.house").font(.system(size: 48)).foregroundColor(.gray)
                            Text(langManager.text("İstediğin şarkıyı arat ve yt-dlp ile indir.", "Search a song and download via yt-dlp."))
                                .font(.subheadline).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchResults) { song in
                                    SongRowView(song: song)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.searchResults = [
                Song(id: "yt_1", title: "\(searchQuery) (Bass Boosted)", artist: "OutLine Audio", duration: "3:15"),
                Song(id: "yt_2", title: "\(searchQuery) (Remix Version)", artist: "Club Sounds", duration: "2:45"),
                Song(id: "yt_3", title: "\(searchQuery) (Live Concert)", artist: "Live Channel", duration: "4:20")
            ]
            self.isLoading = false
        }
    }
}

// MARK: - Şarkı Satırı Kartı
struct SongRowView: View {
    let song: Song
    @EnvironmentObject var musicManager: MusicPlayerManager
    
    var body: some View {
        HStack(spacing: 14) {
            Button(action: {
                musicManager.playSong(song)
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.25, green: 0.25, blue: 0.28))
                            .frame(width: 56, height: 56)
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Text(song.artist).font(.system(size: 13)).foregroundColor(.gray)
                            Text("•").font(.system(size: 13)).foregroundColor(.gray)
                            Text(song.duration).font(.system(size: 13)).foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
            
            // yt-dlp İndir Butonu
            Button(action: {
                musicManager.downloadWithYtDlp(song)
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.22, green: 0.22, blue: 0.25))
                        .frame(width: 38, height: 38)
                    
                    if musicManager.isDownloading(song.id) {
                        ProgressView().tint(.white)
                    } else if musicManager.isDownloaded(song.id) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(red: 0.16, green: 0.16, blue: 0.18))
        .cornerRadius(12)
    }
}

// MARK: - 2. Kütüphane ve Çalma Listeleri Ekranı
struct LibraryView: View {
    let backgroundColor: Color
    @EnvironmentObject var langManager: LanguageManager
    @EnvironmentObject var musicManager: MusicPlayerManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(langManager.text("Kütüphane", "Library"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // İndirilenler Bölümü
                        VStack(alignment: .leading, spacing: 10) {
                            Text(langManager.text("İndirilen Şarkılar", "Downloaded Songs"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if musicManager.downloadedSongs.isEmpty {
                                Text(langManager.text("Henüz yt-dlp ile indirilmiş şarkı yok.", "No songs downloaded via yt-dlp yet."))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            } else {
                                ForEach(musicManager.downloadedSongs) { song in
                                    SongRowView(song: song)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Çalma Listeleri Bölümü
                        VStack(alignment: .leading, spacing: 10) {
                            Text(langManager.text("Çalma Listelerim", "My Playlists"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.top, 10)
                            
                            ForEach(musicManager.playlists) { playlist in
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                        .frame(width: 40, height: 40)
                                        .background(Color(red: 0.22, green: 0.22, blue: 0.25))
                                        .cornerRadius(8)
                                    
                                    Text(playlist.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(playlist.songs.count) " + langManager.text("şarkı", "songs"))
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(red: 0.16, green: 0.16, blue: 0.18))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 3. Ayarlar Ekranı
struct SettingsView: View {
    let backgroundColor: Color
    @EnvironmentObject var langManager: LanguageManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Text(langManager.text("Ayarlar", "Settings"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(langManager.text("Uygulama Dili", "App Language"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Language")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Spacer()
                            
                            Picker("", selection: $langManager.currentLanguage) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Text(lang.titleName).tag(lang)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                        }
                        .padding()
                        .background(Color(red: 0.18, green: 0.18, blue: 0.20))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}
