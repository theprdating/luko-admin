// 興趣與問答共用資料
//
// 供申請流程（apply_interests_page.dart）和個人資料頁（my_profile_page.dart、
// edit_profile_page.dart）共同使用。
//
// 使用方式：
//   final name = kInterestLookup['music_pop']?.label('zh') ?? 'music_pop';

// ── 興趣資料 ──────────────────────────────────────────────────────────────────

class InterestItem {
  const InterestItem(this.id, this.zh, this.en);
  final String id;
  final String zh;
  final String en;
  String label(String languageCode) => languageCode == 'zh' ? zh : en;
}

class InterestCategory {
  const InterestCategory({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.items,
  });
  final String id;
  final String labelZh;
  final String labelEn;
  final List<InterestItem> items;
  String label(String languageCode) => languageCode == 'zh' ? labelZh : labelEn;
}

const kInterestCategories = <InterestCategory>[
  InterestCategory(
    id: 'music', labelZh: '音樂', labelEn: 'Music',
    items: [
      InterestItem('music_pop', '流行音樂', 'Pop'),
      InterestItem('music_rock', '搖滾', 'Rock'),
      InterestItem('music_jazz', '爵士', 'Jazz'),
      InterestItem('music_classical', '古典音樂', 'Classical'),
      InterestItem('music_hiphop', '嘻哈', 'Hip-hop'),
      InterestItem('music_electronic', '電子音樂', 'Electronic'),
      InterestItem('music_rnb', 'R&B', 'R&B'),
      InterestItem('music_folk', '民謠', 'Folk'),
      InterestItem('music_indie', '獨立音樂', 'Indie'),
      InterestItem('music_kpop', 'K-pop', 'K-pop'),
      InterestItem('music_jpop', 'J-pop', 'J-pop'),
      InterestItem('music_tw_pop', '台灣流行', 'Taiwanese Pop'),
      InterestItem('music_metal', '金屬', 'Metal'),
      InterestItem('music_blues', '藍調', 'Blues'),
      InterestItem('music_soul', '靈魂樂', 'Soul'),
      InterestItem('music_bossa_nova', 'Bossa Nova', 'Bossa Nova'),
      InterestItem('music_instrumental', '器樂演奏', 'Instrumental'),
      InterestItem('music_piano', '鋼琴', 'Piano'),
      InterestItem('music_guitar', '吉他', 'Guitar'),
      InterestItem('music_production', '音樂製作', 'Music Production'),
      InterestItem('music_band', '樂團', 'Band'),
      InterestItem('music_karaoke', '卡拉OK', 'Karaoke'),
      InterestItem('music_concert', '演唱會', 'Live Concert'),
      InterestItem('music_festival', '音樂節', 'Music Festival'),
      InterestItem('music_vinyl', '黑膠唱片', 'Vinyl'),
    ],
  ),
  InterestCategory(
    id: 'entertainment', labelZh: '影視', labelEn: 'Film & TV',
    items: [
      InterestItem('ent_action', '動作片', 'Action'),
      InterestItem('ent_romance', '愛情電影', 'Romance'),
      InterestItem('ent_thriller', '驚悚懸疑', 'Thriller'),
      InterestItem('ent_scifi', '科幻電影', 'Sci-fi'),
      InterestItem('ent_documentary', '紀錄片', 'Documentary'),
      InterestItem('ent_animation', '動畫', 'Animation'),
      InterestItem('ent_comedy', '喜劇', 'Comedy'),
      InterestItem('ent_horror', '恐怖片', 'Horror'),
      InterestItem('ent_historical', '歷史片', 'Historical'),
      InterestItem('ent_art_film', '藝術電影', 'Art Film'),
      InterestItem('ent_indie_film', '獨立電影', 'Indie Film'),
      InterestItem('ent_kdrama', '韓劇', 'K-drama'),
      InterestItem('ent_us_drama', '美劇', 'US Drama'),
      InterestItem('ent_jdrama', '日劇', 'J-drama'),
      InterestItem('ent_tw_drama', '台劇', 'Taiwanese Drama'),
      InterestItem('ent_netflix', 'Netflix', 'Netflix'),
      InterestItem('ent_disney_plus', 'Disney+', 'Disney+'),
      InterestItem('ent_short_video', '短影音', 'Short Video'),
      InterestItem('ent_anime', '動漫', 'Anime'),
      InterestItem('ent_demon_slayer', '鬼滅之刃', 'Demon Slayer'),
      InterestItem('ent_aot', '進擊的巨人', 'Attack on Titan'),
      InterestItem('ent_jjk', '咒術迴戰', 'Jujutsu Kaisen'),
      InterestItem('ent_one_piece', '海賊王', 'One Piece'),
      InterestItem('ent_naruto', '火影忍者', 'Naruto'),
      InterestItem('ent_spy_family', '間諜家家酒', 'Spy × Family'),
      InterestItem('ent_frieren', '葬送的芙莉蓮', 'Frieren'),
      InterestItem('ent_harry_potter', '哈利波特', 'Harry Potter'),
      InterestItem('ent_lotr', '魔戒', 'Lord of the Rings'),
      InterestItem('ent_star_wars', '星際大戰', 'Star Wars'),
      InterestItem('ent_mcu', '漫威宇宙', 'MCU'),
      InterestItem('ent_dc', 'DC宇宙', 'DC Universe'),
      InterestItem('ent_got', '權力的遊戲', 'Game of Thrones'),
      InterestItem('ent_stranger_things', '怪奇物語', 'Stranger Things'),
      InterestItem('ent_dune', '沙丘', 'Dune'),
      InterestItem('ent_matrix', '駭客任務', 'The Matrix'),
      InterestItem('ent_soundtracks', '電影原聲帶', 'Soundtracks'),
      InterestItem('ent_new_releases', '院線新片', 'New Releases'),
    ],
  ),
  InterestCategory(
    id: 'food', labelZh: '美食', labelEn: 'Food',
    items: [
      InterestItem('food_ramen', '拉麵', 'Ramen'),
      InterestItem('food_sushi', '壽司', 'Sushi'),
      InterestItem('food_hotpot', '火鍋', 'Hot Pot'),
      InterestItem('food_bbq', '燒烤', 'BBQ'),
      InterestItem('food_italian', '義大利料理', 'Italian'),
      InterestItem('food_french', '法式料理', 'French'),
      InterestItem('food_thai', '泰式料理', 'Thai'),
      InterestItem('food_korean', '韓式料理', 'Korean'),
      InterestItem('food_indian', '印度料理', 'Indian'),
      InterestItem('food_chinese', '中式料理', 'Chinese'),
      InterestItem('food_brunch', '早午餐', 'Brunch'),
      InterestItem('food_desserts', '甜點', 'Desserts'),
      InterestItem('food_coffee', '咖啡', 'Coffee'),
      InterestItem('food_bubble_tea', '手搖飲', 'Bubble Tea'),
      InterestItem('food_baking', '烘焙', 'Baking'),
      InterestItem('food_home_cooking', '自煮料理', 'Home Cooking'),
      InterestItem('food_michelin', '米其林', 'Michelin'),
      InterestItem('food_night_market', '夜市美食', 'Night Market'),
      InterestItem('food_seafood', '海鮮', 'Seafood'),
      InterestItem('food_vegetarian', '素食', 'Vegetarian'),
      InterestItem('food_healthy', '健康飲食', 'Healthy Eating'),
      InterestItem('food_izakaya', '串燒居酒屋', 'Izakaya'),
      InterestItem('food_spicy_hotpot', '麻辣燙', 'Spicy Hot Pot'),
      InterestItem('food_dim_sum', '港式飲茶', 'Dim Sum'),
      InterestItem('food_afternoon_tea', '下午茶', 'Afternoon Tea'),
    ],
  ),
  InterestCategory(
    id: 'travel', labelZh: '旅行', labelEn: 'Travel',
    items: [
      InterestItem('travel_backpacking', '背包客旅行', 'Backpacking'),
      InterestItem('travel_luxury', '奢華旅遊', 'Luxury Travel'),
      InterestItem('travel_city', '城市探索', 'City Exploring'),
      InterestItem('travel_island', '海島度假', 'Island Getaway'),
      InterestItem('travel_hiking', '山林健行', 'Hiking'),
      InterestItem('travel_cultural', '文化深度遊', 'Cultural Travel'),
      InterestItem('travel_road_trip', 'Road Trip', 'Road Trip'),
      InterestItem('travel_solo', '獨旅', 'Solo Travel'),
      InterestItem('travel_airbnb', 'Airbnb', 'Airbnb'),
      InterestItem('travel_camping', '露營', 'Camping'),
      InterestItem('travel_ski', '滑雪旅行', 'Ski Trip'),
      InterestItem('travel_food_tourism', '跟著美食旅行', 'Food Tourism'),
      InterestItem('travel_europe', '歐洲旅行', 'Europe'),
      InterestItem('travel_sea', '東南亞', 'Southeast Asia'),
      InterestItem('travel_japan', '日本', 'Japan'),
      InterestItem('travel_taiwan', '台灣在地旅行', 'Taiwan Local'),
      InterestItem('travel_polar', '極地旅行', 'Polar Travel'),
      InterestItem('travel_weekend', '短途小旅行', 'Weekend Trips'),
      InterestItem('travel_working_holiday', '打工度假', 'Working Holiday'),
    ],
  ),
  InterestCategory(
    id: 'lifestyle', labelZh: '生活風格', labelEn: 'Lifestyle',
    items: [
      InterestItem('life_cafe', '咖啡廳探索', 'Café Hopping'),
      InterestItem('life_home_decor', '居家佈置', 'Home Decor'),
      InterestItem('life_fashion', '時尚穿搭', 'Fashion'),
      InterestItem('life_beauty', '美妝保養', 'Beauty & Skincare'),
      InterestItem('life_wellness', '健康養生', 'Wellness'),
      InterestItem('life_sustainability', '可持續生活', 'Sustainability'),
      InterestItem('life_thrift', '二手古著', 'Thrift & Vintage'),
      InterestItem('life_diy', 'DIY改造', 'DIY'),
      InterestItem('life_aromatherapy', '香薰香氛', 'Aromatherapy'),
      InterestItem('life_astrology', '占星塔羅', 'Astrology & Tarot'),
      InterestItem('life_board_games', '桌遊', 'Board Games'),
      InterestItem('life_escape_room', '密室逃脫', 'Escape Room'),
      InterestItem('life_slow_living', '慢活', 'Slow Living'),
      InterestItem('life_minimalism', '極簡主義', 'Minimalism'),
      InterestItem('life_art_gallery', '美術館', 'Art Gallery'),
      InterestItem('life_museum', '博物館', 'Museum'),
      InterestItem('life_theatre', '劇場表演', 'Theatre'),
      InterestItem('life_standup', '脫口秀', 'Stand-up Comedy'),
      InterestItem('life_volunteering', '志工服務', 'Volunteering'),
    ],
  ),
  InterestCategory(
    id: 'sports', labelZh: '運動', labelEn: 'Sports',
    items: [
      InterestItem('sport_basketball', '籃球', 'Basketball'),
      InterestItem('sport_soccer', '足球', 'Soccer'),
      InterestItem('sport_badminton', '羽毛球', 'Badminton'),
      InterestItem('sport_swimming', '游泳', 'Swimming'),
      InterestItem('sport_running', '跑步', 'Running'),
      InterestItem('sport_gym', '健身重訓', 'Gym & Weightlifting'),
      InterestItem('sport_yoga', '瑜伽', 'Yoga'),
      InterestItem('sport_hiking', '爬山登山', 'Hiking'),
      InterestItem('sport_table_tennis', '桌球', 'Table Tennis'),
      InterestItem('sport_tennis', '網球', 'Tennis'),
      InterestItem('sport_baseball', '棒球', 'Baseball'),
      InterestItem('sport_volleyball', '排球', 'Volleyball'),
      InterestItem('sport_golf', '高爾夫', 'Golf'),
      InterestItem('sport_skateboarding', '滑板', 'Skateboarding'),
      InterestItem('sport_surfing', '衝浪', 'Surfing'),
      InterestItem('sport_cycling', '騎單車', 'Cycling'),
      InterestItem('sport_martial_arts', '格鬥武術', 'Martial Arts'),
      InterestItem('sport_dance', '舞蹈', 'Dance'),
      InterestItem('sport_climbing', '攀岩', 'Rock Climbing'),
      InterestItem('sport_skiing', '滑雪', 'Skiing'),
      InterestItem('sport_triathlon', '鐵人三項', 'Triathlon'),
      InterestItem('sport_crossfit', 'CrossFit', 'CrossFit'),
      InterestItem('sport_pilates', '皮拉提斯', 'Pilates'),
      InterestItem('sport_marathon', '馬拉松', 'Marathon'),
      InterestItem('sport_frisbee', '飛盤', 'Frisbee'),
      InterestItem('sport_pickleball', '匹克球', 'Pickleball'),
    ],
  ),
  InterestCategory(
    id: 'pets', labelZh: '寵物', labelEn: 'Pets',
    items: [
      InterestItem('pet_cats', '貓咪', 'Cats'),
      InterestItem('pet_dogs', '狗狗', 'Dogs'),
      InterestItem('pet_rabbits', '兔子', 'Rabbits'),
      InterestItem('pet_hamsters', '倉鼠', 'Hamsters'),
      InterestItem('pet_birds', '鳥類', 'Birds'),
      InterestItem('pet_fish', '觀賞魚', 'Fish'),
      InterestItem('pet_reptiles', '爬蟲類', 'Reptiles'),
      InterestItem('pet_guinea_pigs', '天竺鼠', 'Guinea Pigs'),
      InterestItem('pet_hedgehogs', '刺蝟', 'Hedgehogs'),
      InterestItem('pet_amphibians', '兩棲類', 'Amphibians'),
      InterestItem('pet_adoption', '退役犬貓認養', 'Pet Adoption'),
      InterestItem('pet_photography', '寵物攝影', 'Pet Photography'),
      InterestItem('pet_walking', '寵物溜達', 'Pet Walking'),
      InterestItem('pet_volunteering', '動物志工', 'Animal Volunteering'),
      InterestItem('pet_zoo', '動物園', 'Zoo'),
      InterestItem('pet_aquarium', '水族館', 'Aquarium'),
    ],
  ),
  InterestCategory(
    id: 'artists', labelZh: '藝人', labelEn: 'Artists',
    items: [
      InterestItem('artist_jay_chou', '周杰倫', 'Jay Chou'),
      InterestItem('artist_mayday', '五月天', 'Mayday'),
      InterestItem('artist_jolin', '蔡依林', 'Jolin Tsai'),
      InterestItem('artist_jj_lin', '林俊傑', 'JJ Lin'),
      InterestItem('artist_amei', '張惠妹', 'A-mei'),
      InterestItem('artist_eason', '陳奕迅', 'Eason Chan'),
      InterestItem('artist_crowd_lu', '盧廣仲', 'Crowd Lu'),
      InterestItem('artist_waa_wei', '魏如萱', 'Waa Wei'),
      InterestItem('artist_accusefive', '告五人', 'Accusefive'),
      InterestItem('artist_eggplant_egg', '茄子蛋', 'Eggplant Egg'),
      InterestItem('artist_leo_wang', 'Leo王', 'Leo Wang'),
      InterestItem('artist_9m88', '9m88', '9m88'),
      InterestItem('artist_bts', 'BTS', 'BTS'),
      InterestItem('artist_blackpink', 'BLACKPINK', 'BLACKPINK'),
      InterestItem('artist_twice', 'TWICE', 'TWICE'),
      InterestItem('artist_aespa', 'aespa', 'aespa'),
      InterestItem('artist_newjeans', 'NewJeans', 'NewJeans'),
      InterestItem('artist_ive', 'IVE', 'IVE'),
      InterestItem('artist_seventeen', 'SEVENTEEN', 'SEVENTEEN'),
      InterestItem('artist_stray_kids', 'Stray Kids', 'Stray Kids'),
      InterestItem('artist_le_sserafim', 'LE SSERAFIM', 'LE SSERAFIM'),
      InterestItem('artist_nct_dream', 'NCT DREAM', 'NCT DREAM'),
      InterestItem('artist_kenshi_yonezu', '米津玄師', 'Kenshi Yonezu'),
      InterestItem('artist_gen_hoshino', '星野源', 'Gen Hoshino'),
      InterestItem('artist_hikaru_utada', '宇多田光', 'Hikaru Utada'),
      InterestItem('artist_official_hige', 'Official髭男dism', 'Official髭男dism'),
      InterestItem('artist_fujii_kaze', '藤井風', 'Fujii Kaze'),
      InterestItem('artist_aimyon', 'Aimyon', 'Aimyon'),
      InterestItem('artist_yoasobi', 'YOASOBI', 'YOASOBI'),
      InterestItem('artist_king_gnu', 'King Gnu', 'King Gnu'),
      InterestItem('artist_yuri', '優里', 'Yuri'),
      InterestItem('artist_back_number', 'back number', 'back number'),
      InterestItem('artist_taylor_swift', '泰勒絲', 'Taylor Swift'),
      InterestItem('artist_beyonce', '碧昂絲', 'Beyoncé'),
      InterestItem('artist_the_weeknd', 'The Weeknd', 'The Weeknd'),
      InterestItem('artist_ed_sheeran', '紅髮艾德', 'Ed Sheeran'),
      InterestItem('artist_billie_eilish', 'Billie Eilish', 'Billie Eilish'),
      InterestItem('artist_olivia_rodrigo', 'Olivia Rodrigo', 'Olivia Rodrigo'),
      InterestItem('artist_harry_styles', 'Harry Styles', 'Harry Styles'),
      InterestItem('artist_drake', 'Drake', 'Drake'),
      InterestItem('artist_coldplay', 'Coldplay', 'Coldplay'),
      InterestItem('artist_arctic_monkeys', 'Arctic Monkeys', 'Arctic Monkeys'),
      InterestItem('artist_radiohead', 'Radiohead', 'Radiohead'),
      InterestItem('artist_kendrick_lamar', 'Kendrick Lamar', 'Kendrick Lamar'),
      InterestItem('artist_frank_ocean', 'Frank Ocean', 'Frank Ocean'),
      InterestItem('artist_sza', 'SZA', 'SZA'),
    ],
  ),
  InterestCategory(
    id: 'art', labelZh: '藝術創作', labelEn: 'Arts & Crafts',
    items: [
      InterestItem('art_painting', '繪畫', 'Painting'),
      InterestItem('art_photography', '攝影', 'Photography'),
      InterestItem('art_songwriting', '音樂創作', 'Songwriting'),
      InterestItem('art_writing', '寫作', 'Writing'),
      InterestItem('art_design', '設計', 'Design'),
      InterestItem('art_illustration', '插畫', 'Illustration'),
      InterestItem('art_crafts', '手工藝', 'Crafts'),
      InterestItem('art_pottery', '陶藝', 'Pottery'),
      InterestItem('art_calligraphy', '書法', 'Calligraphy'),
      InterestItem('art_embroidery', '刺繡', 'Embroidery'),
      InterestItem('art_knitting', '編織', 'Knitting'),
      InterestItem('art_sculpture', '雕塑', 'Sculpture'),
      InterestItem('art_street_art', '街頭藝術', 'Street Art'),
      InterestItem('art_digital', '數位藝術', 'Digital Art'),
      InterestItem('art_video_editing', '影片剪輯', 'Video Editing'),
      InterestItem('art_podcast', 'Podcast', 'Podcast'),
      InterestItem('art_fashion_design', '時尚設計', 'Fashion Design'),
      InterestItem('art_interior_design', '室內設計', 'Interior Design'),
      InterestItem('art_floristry', '花藝', 'Floristry'),
      InterestItem('art_leathercraft', '皮革工藝', 'Leathercraft'),
      InterestItem('art_printmaking', '版畫', 'Printmaking'),
      InterestItem('art_watercolor', '水彩', 'Watercolor'),
      InterestItem('art_drawing', '素描', 'Drawing'),
    ],
  ),
  InterestCategory(
    id: 'learning', labelZh: '學習成長', labelEn: 'Self-Growth',
    items: [
      InterestItem('learn_reading', '閱讀', 'Reading'),
      InterestItem('learn_language', '語言學習', 'Language Learning'),
      InterestItem('learn_online_courses', '線上課程', 'Online Courses'),
      InterestItem('learn_meditation', '冥想', 'Meditation'),
      InterestItem('learn_psychology', '心理學', 'Psychology'),
      InterestItem('learn_philosophy', '哲學', 'Philosophy'),
      InterestItem('learn_history', '歷史', 'History'),
      InterestItem('learn_science', '科學', 'Science'),
      InterestItem('learn_public_speaking', '演講表達', 'Public Speaking'),
      InterestItem('learn_time_mgmt', '時間管理', 'Time Management'),
      InterestItem('learn_investing', '投資理財', 'Investing'),
      InterestItem('learn_entrepreneurship', '創業', 'Entrepreneurship'),
      InterestItem('learn_business', '商業管理', 'Business'),
      InterestItem('learn_ted', 'TED Talks', 'TED Talks'),
      InterestItem('learn_personal_growth', '自我成長', 'Personal Growth'),
      InterestItem('learn_mindfulness', '正念', 'Mindfulness'),
    ],
  ),
  InterestCategory(
    id: 'drinks', labelZh: '酒飲', labelEn: 'Drinks',
    items: [
      InterestItem('drink_draft_beer', '生啤', 'Draft Beer'),
      InterestItem('drink_craft_beer', '精釀啤酒', 'Craft Beer'),
      InterestItem('drink_stout', '黑啤', 'Stout'),
      InterestItem('drink_ipa', 'IPA', 'IPA'),
      InterestItem('drink_wheat_beer', '小麥啤酒', 'Wheat Beer'),
      InterestItem('drink_trappist', '比利時修道院啤酒', 'Trappist'),
      InterestItem('drink_single_malt', '單一麥芽威士忌', 'Single Malt'),
      InterestItem('drink_japanese_whisky', '日本威士忌', 'Japanese Whisky'),
      InterestItem('drink_bourbon', '波本威士忌', 'Bourbon'),
      InterestItem('drink_irish_whiskey', '愛爾蘭威士忌', 'Irish Whiskey'),
      InterestItem('drink_blended_whisky', '調和威士忌', 'Blended Whisky'),
      InterestItem('drink_gin', '琴酒', 'Gin'),
      InterestItem('drink_vodka', '伏特加', 'Vodka'),
      InterestItem('drink_rum', '蘭姆酒', 'Rum'),
      InterestItem('drink_tequila', '龍舌蘭', 'Tequila'),
      InterestItem('drink_brandy', '白蘭地', 'Brandy'),
      InterestItem('drink_sake', '清酒', 'Sake'),
      InterestItem('drink_shochu', '燒酎', 'Shochu'),
      InterestItem('drink_plum_wine', '梅酒', 'Plum Wine'),
      InterestItem('drink_red_wine', '紅酒', 'Red Wine'),
      InterestItem('drink_white_wine', '白葡萄酒', 'White Wine'),
      InterestItem('drink_natural_wine', '自然酒', 'Natural Wine'),
      InterestItem('drink_champagne', '香檳', 'Champagne'),
      InterestItem('drink_prosecco', '氣泡酒', 'Prosecco'),
      InterestItem('drink_martini', '馬丁尼', 'Martini'),
      InterestItem('drink_negroni', '內格羅尼', 'Negroni'),
      InterestItem('drink_old_fashioned', '老式雞尾酒', 'Old Fashioned'),
      InterestItem('drink_mojito', '莫西多', 'Mojito'),
      InterestItem('drink_aperol_spritz', '艾普羅氣泡酒', 'Aperol Spritz'),
      InterestItem('drink_whiskey_sour', '威士忌酸', 'Whiskey Sour'),
      InterestItem('drink_gin_tonic', '琴通寧', 'Gin & Tonic'),
      InterestItem('drink_long_island', 'Long Island Iced Tea', 'Long Island Iced Tea'),
      InterestItem('drink_whisky_tasting', '威士忌品飲', 'Whisky Tasting'),
      InterestItem('drink_mixology', '調酒課', 'Mixology Class'),
      InterestItem('drink_wine_pairing', '葡萄酒配餐', 'Wine Pairing'),
      InterestItem('drink_bar_hopping', '清吧小酌', 'Bar Hopping'),
      InterestItem('drink_izakaya', '居酒屋', 'Izakaya'),
    ],
  ),
  InterestCategory(
    id: 'tech', labelZh: '科技', labelEn: 'Tech',
    items: [
      InterestItem('tech_coding', '程式設計', 'Coding'),
      InterestItem('tech_ai', 'AI / 機器學習', 'AI / Machine Learning'),
      InterestItem('tech_gaming', '遊戲', 'Gaming'),
      InterestItem('tech_esports', '電競', 'Esports'),
      InterestItem('tech_vr', '虛擬實境', 'VR/AR'),
      InterestItem('tech_3d_printing', '3D列印', '3D Printing'),
      InterestItem('tech_drones', '無人機', 'Drones'),
      InterestItem('tech_smart_home', '智慧家庭', 'Smart Home'),
      InterestItem('tech_crypto', '加密貨幣', 'Crypto'),
      InterestItem('tech_news', '科技新聞', 'Tech News'),
      InterestItem('tech_app_design', 'App設計', 'App Design'),
      InterestItem('tech_open_source', '開源軟體', 'Open Source'),
      InterestItem('tech_robotics', '機器人', 'Robotics'),
      InterestItem('tech_cybersecurity', '資訊安全', 'Cybersecurity'),
    ],
  ),
];

/// 快速 ID → InterestItem 查找表（O(1) 查詢）
final Map<String, InterestItem> kInterestLookup = {
  for (final cat in kInterestCategories)
    for (final item in cat.items)
      item.id: item,
};

// ── 問答資料 ──────────────────────────────────────────────────────────────────

class QuestionItem {
  const QuestionItem({required this.id, required this.text});
  final String id;
  final String text;
}

class QuestionCategory {
  const QuestionCategory({
    required this.id,
    required this.label,
    required this.questions,
  });
  final String id;
  final String label;
  final List<QuestionItem> questions;
}

const kQuestionCategories = <QuestionCategory>[
  QuestionCategory(
    id: 'daily', label: '日常生活',
    questions: [
      QuestionItem(id: 'daily_1', text: '你是早起型還是夜貓子？'),
      QuestionItem(id: 'daily_2', text: '描述你理想的週末是什麼樣子？'),
      QuestionItem(id: 'daily_3', text: '你早餐通常吃什麼？'),
      QuestionItem(id: 'daily_4', text: '工作日的你和假日的你，最大的差別是？'),
      QuestionItem(id: 'daily_5', text: '你在家最喜歡做什麼？'),
      QuestionItem(id: 'daily_6', text: '你是整理控還是享受微亂的人？'),
      QuestionItem(id: 'daily_7', text: '你一天沒有哪件事不行？'),
    ],
  ),
  QuestionCategory(
    id: 'food', label: '飲食品味',
    questions: [
      QuestionItem(id: 'food_1', text: '你喜歡自己煮還是出去吃？'),
      QuestionItem(id: 'food_2', text: '你有沒有一道會煮的拿手菜？'),
      QuestionItem(id: 'food_3', text: '最近讓你念念不忘的一道料理是？'),
      QuestionItem(id: 'food_4', text: '你對食物有什麼特別的堅持或偏好？'),
      QuestionItem(id: 'food_5', text: '你覺得一起吃飯最重要的是？'),
      QuestionItem(id: 'food_6', text: '你對咖啡或手搖飲有什麼儀式感嗎？'),
    ],
  ),
  QuestionCategory(
    id: 'travel', label: '旅行',
    questions: [
      QuestionItem(id: 'travel_1', text: '你旅行時更喜歡計畫好一切，還是隨性出發？'),
      QuestionItem(id: 'travel_2', text: '到目前為止最難忘的旅行是哪一次？'),
      QuestionItem(id: 'travel_3', text: '你的清單上有哪個地方一定要去？'),
      QuestionItem(id: 'travel_4', text: '你喜歡城市旅行還是自然旅行？'),
      QuestionItem(id: 'travel_5', text: '如果可以一個人去旅行一個月，你會選哪裡？'),
    ],
  ),
  QuestionCategory(
    id: 'relationship', label: '感情觀',
    questions: [
      QuestionItem(id: 'rel_1', text: '你認為愛情裡最重要的一件事是什麼？'),
      QuestionItem(id: 'rel_2', text: '你的愛之語是哪一種？'),
      QuestionItem(id: 'rel_3', text: '你喜歡每天保持聯繫，還是各自有空間的相處模式？'),
      QuestionItem(id: 'rel_4', text: '你覺得兩個人「合適」的關鍵是什麼？'),
      QuestionItem(id: 'rel_5', text: '你理想中的第一次約會是什麼樣子？'),
    ],
  ),
  QuestionCategory(
    id: 'pace', label: '生活步調',
    questions: [
      QuestionItem(id: 'pace_1', text: '你偏向快節奏還是慢生活？'),
      QuestionItem(id: 'pace_2', text: '你如何在忙碌中讓自己放鬆？'),
      QuestionItem(id: 'pace_3', text: '你面對壓力的方式是什麼？'),
      QuestionItem(id: 'pace_4', text: '你的社交電量能撐多久？'),
      QuestionItem(id: 'pace_5', text: '你更享受熱鬧的社交場合，還是安靜的兩人相處？'),
    ],
  ),
  QuestionCategory(
    id: 'values', label: '價值觀',
    questions: [
      QuestionItem(id: 'val_1', text: '你人生目前最在乎的一件事是什麼？'),
      QuestionItem(id: 'val_2', text: '你對「成功」的定義是什麼？'),
      QuestionItem(id: 'val_3', text: '你覺得金錢在生活中扮演什麼角色？'),
      QuestionItem(id: 'val_4', text: '你有沒有什麼事情是絕對不願意妥協的？'),
      QuestionItem(id: 'val_5', text: '你覺得善良和能力，哪個更重要？'),
    ],
  ),
  QuestionCategory(
    id: 'family', label: '家庭與未來',
    questions: [
      QuestionItem(id: 'fam_1', text: '你對婚姻的想法是什麼？'),
      QuestionItem(id: 'fam_2', text: '你想不想要孩子？'),
      QuestionItem(id: 'fam_3', text: '你希望五年後自己的生活是什麼樣子？'),
      QuestionItem(id: 'fam_4', text: '你和家人的關係是怎麼樣的？'),
      QuestionItem(id: 'fam_5', text: '你理想中的「家」是什麼感覺？'),
    ],
  ),
  QuestionCategory(
    id: 'personality', label: '個性特質',
    questions: [
      QuestionItem(id: 'per_1', text: '用三個詞形容你自己？'),
      QuestionItem(id: 'per_2', text: '你的朋友會怎麼描述你？'),
      QuestionItem(id: 'per_3', text: '你是計畫型還是隨興型的人？'),
      QuestionItem(id: 'per_4', text: '你在什麼時候最有活力？'),
      QuestionItem(id: 'per_5', text: '你覺得自己最大的優點和缺點是什麼？'),
    ],
  ),
  QuestionCategory(
    id: 'fun', label: '輕鬆有趣',
    questions: [
      QuestionItem(id: 'fun_1', text: '如果今晚可以做任何事，你會選擇什麼？'),
      QuestionItem(id: 'fun_2', text: '你有什麼讓人意外的冷知識或技能？'),
      QuestionItem(id: 'fun_3', text: '你最近笑得最開心的一次是什麼？'),
      QuestionItem(id: 'fun_4', text: '如果你是一道料理，你會是什麼？'),
      QuestionItem(id: 'fun_5', text: '你有什麼獨特的小怪癖嗎？'),
      QuestionItem(id: 'fun_6', text: '如果可以和任何一個歷史人物吃飯，你選誰？'),
    ],
  ),
];

/// 快速 InterestItem ID → 所屬 InterestCategory（O(1) 查詢）
///
/// 用於 profile 頁依類別分組顯示興趣，避免每次 O(n²) 遍歷。
final Map<String, InterestCategory> kInterestCategoryOf = {
  for (final cat in kInterestCategories)
    for (final item in cat.items)
      item.id: cat,
};

/// 快速 ID → QuestionItem 查找表（O(1) 查詢）
final Map<String, QuestionItem> kQuestionLookup = {
  for (final cat in kQuestionCategories)
    for (final q in cat.questions)
      q.id: q,
};
