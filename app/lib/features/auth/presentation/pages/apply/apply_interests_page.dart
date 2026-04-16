import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/supabase/supabase_provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/luko_button.dart';
import '../../../../../core/widgets/luko_loading_overlay.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';

// ── 興趣資料 ──────────────────────────────────────────────────────────────────

/// 單一興趣選項：[id] 存入 DB，[zh]/[en] 根據 locale 顯示。
class _InterestItem {
  const _InterestItem(this.id, this.zh, this.en);
  final String id;
  final String zh;
  final String en;
  String label(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

class _InterestCategory {
  const _InterestCategory({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.items,
  });

  final String id;
  final String labelZh;
  final String labelEn;
  final List<_InterestItem> items;
  String label(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'zh' ? labelZh : labelEn;
}

const _kCategories = [
  _InterestCategory(
    id: 'music', labelZh: '音樂', labelEn: 'Music',
    items: [
      _InterestItem('music_pop', '流行音樂', 'Pop'),
      _InterestItem('music_rock', '搖滾', 'Rock'),
      _InterestItem('music_jazz', '爵士', 'Jazz'),
      _InterestItem('music_classical', '古典音樂', 'Classical'),
      _InterestItem('music_hiphop', '嘻哈', 'Hip-hop'),
      _InterestItem('music_electronic', '電子音樂', 'Electronic'),
      _InterestItem('music_rnb', 'R&B', 'R&B'),
      _InterestItem('music_folk', '民謠', 'Folk'),
      _InterestItem('music_indie', '獨立音樂', 'Indie'),
      _InterestItem('music_kpop', 'K-pop', 'K-pop'),
      _InterestItem('music_jpop', 'J-pop', 'J-pop'),
      _InterestItem('music_tw_pop', '台灣流行', 'Taiwanese Pop'),
      _InterestItem('music_metal', '金屬', 'Metal'),
      _InterestItem('music_blues', '藍調', 'Blues'),
      _InterestItem('music_soul', '靈魂樂', 'Soul'),
      _InterestItem('music_bossa_nova', 'Bossa Nova', 'Bossa Nova'),
      _InterestItem('music_instrumental', '器樂演奏', 'Instrumental'),
      _InterestItem('music_piano', '鋼琴', 'Piano'),
      _InterestItem('music_guitar', '吉他', 'Guitar'),
      _InterestItem('music_production', '音樂製作', 'Music Production'),
      _InterestItem('music_band', '樂團', 'Band'),
      _InterestItem('music_karaoke', '卡拉OK', 'Karaoke'),
      _InterestItem('music_concert', '演唱會', 'Live Concert'),
      _InterestItem('music_festival', '音樂節', 'Music Festival'),
      _InterestItem('music_vinyl', '黑膠唱片', 'Vinyl'),
    ],
  ),
  _InterestCategory(
    id: 'entertainment', labelZh: '影視', labelEn: 'Film & TV',
    items: [
      _InterestItem('ent_action', '動作片', 'Action'),
      _InterestItem('ent_romance', '愛情電影', 'Romance'),
      _InterestItem('ent_thriller', '驚悚懸疑', 'Thriller'),
      _InterestItem('ent_scifi', '科幻電影', 'Sci-fi'),
      _InterestItem('ent_documentary', '紀錄片', 'Documentary'),
      _InterestItem('ent_animation', '動畫', 'Animation'),
      _InterestItem('ent_comedy', '喜劇', 'Comedy'),
      _InterestItem('ent_horror', '恐怖片', 'Horror'),
      _InterestItem('ent_historical', '歷史片', 'Historical'),
      _InterestItem('ent_art_film', '藝術電影', 'Art Film'),
      _InterestItem('ent_indie_film', '獨立電影', 'Indie Film'),
      _InterestItem('ent_kdrama', '韓劇', 'K-drama'),
      _InterestItem('ent_us_drama', '美劇', 'US Drama'),
      _InterestItem('ent_jdrama', '日劇', 'J-drama'),
      _InterestItem('ent_tw_drama', '台劇', 'Taiwanese Drama'),
      _InterestItem('ent_netflix', 'Netflix', 'Netflix'),
      _InterestItem('ent_disney_plus', 'Disney+', 'Disney+'),
      _InterestItem('ent_short_video', '短影音', 'Short Video'),
      _InterestItem('ent_anime', '動漫', 'Anime'),
      _InterestItem('ent_demon_slayer', '鬼滅之刃', 'Demon Slayer'),
      _InterestItem('ent_aot', '進擊的巨人', 'Attack on Titan'),
      _InterestItem('ent_jjk', '咒術迴戰', 'Jujutsu Kaisen'),
      _InterestItem('ent_one_piece', '海賊王', 'One Piece'),
      _InterestItem('ent_naruto', '火影忍者', 'Naruto'),
      _InterestItem('ent_spy_family', '間諜家家酒', 'Spy × Family'),
      _InterestItem('ent_frieren', '葬送的芙莉蓮', 'Frieren'),
      _InterestItem('ent_harry_potter', '哈利波特', 'Harry Potter'),
      _InterestItem('ent_lotr', '魔戒', 'Lord of the Rings'),
      _InterestItem('ent_star_wars', '星際大戰', 'Star Wars'),
      _InterestItem('ent_mcu', '漫威宇宙', 'MCU'),
      _InterestItem('ent_dc', 'DC宇宙', 'DC Universe'),
      _InterestItem('ent_got', '權力的遊戲', 'Game of Thrones'),
      _InterestItem('ent_stranger_things', '怪奇物語', 'Stranger Things'),
      _InterestItem('ent_dune', '沙丘', 'Dune'),
      _InterestItem('ent_matrix', '駭客任務', 'The Matrix'),
      _InterestItem('ent_soundtracks', '電影原聲帶', 'Soundtracks'),
      _InterestItem('ent_new_releases', '院線新片', 'New Releases'),
    ],
  ),
  _InterestCategory(
    id: 'food', labelZh: '美食', labelEn: 'Food',
    items: [
      _InterestItem('food_ramen', '拉麵', 'Ramen'),
      _InterestItem('food_sushi', '壽司', 'Sushi'),
      _InterestItem('food_hotpot', '火鍋', 'Hot Pot'),
      _InterestItem('food_bbq', '燒烤', 'BBQ'),
      _InterestItem('food_italian', '義大利料理', 'Italian'),
      _InterestItem('food_french', '法式料理', 'French'),
      _InterestItem('food_thai', '泰式料理', 'Thai'),
      _InterestItem('food_korean', '韓式料理', 'Korean'),
      _InterestItem('food_indian', '印度料理', 'Indian'),
      _InterestItem('food_chinese', '中式料理', 'Chinese'),
      _InterestItem('food_brunch', '早午餐', 'Brunch'),
      _InterestItem('food_desserts', '甜點', 'Desserts'),
      _InterestItem('food_coffee', '咖啡', 'Coffee'),
      _InterestItem('food_bubble_tea', '手搖飲', 'Bubble Tea'),
      _InterestItem('food_baking', '烘焙', 'Baking'),
      _InterestItem('food_home_cooking', '自煮料理', 'Home Cooking'),
      _InterestItem('food_michelin', '米其林', 'Michelin'),
      _InterestItem('food_night_market', '夜市美食', 'Night Market'),
      _InterestItem('food_seafood', '海鮮', 'Seafood'),
      _InterestItem('food_vegetarian', '素食', 'Vegetarian'),
      _InterestItem('food_healthy', '健康飲食', 'Healthy Eating'),
      _InterestItem('food_izakaya', '串燒居酒屋', 'Izakaya'),
      _InterestItem('food_spicy_hotpot', '麻辣燙', 'Spicy Hot Pot'),
      _InterestItem('food_dim_sum', '港式飲茶', 'Dim Sum'),
      _InterestItem('food_afternoon_tea', '下午茶', 'Afternoon Tea'),
    ],
  ),
  _InterestCategory(
    id: 'travel', labelZh: '旅行', labelEn: 'Travel',
    items: [
      _InterestItem('travel_backpacking', '背包客旅行', 'Backpacking'),
      _InterestItem('travel_luxury', '奢華旅遊', 'Luxury Travel'),
      _InterestItem('travel_city', '城市探索', 'City Exploring'),
      _InterestItem('travel_island', '海島度假', 'Island Getaway'),
      _InterestItem('travel_hiking', '山林健行', 'Hiking'),
      _InterestItem('travel_cultural', '文化深度遊', 'Cultural Travel'),
      _InterestItem('travel_road_trip', 'Road Trip', 'Road Trip'),
      _InterestItem('travel_solo', '獨旅', 'Solo Travel'),
      _InterestItem('travel_airbnb', 'Airbnb', 'Airbnb'),
      _InterestItem('travel_camping', '露營', 'Camping'),
      _InterestItem('travel_ski', '滑雪旅行', 'Ski Trip'),
      _InterestItem('travel_food_tourism', '跟著美食旅行', 'Food Tourism'),
      _InterestItem('travel_europe', '歐洲旅行', 'Europe'),
      _InterestItem('travel_sea', '東南亞', 'Southeast Asia'),
      _InterestItem('travel_japan', '日本', 'Japan'),
      _InterestItem('travel_taiwan', '台灣在地旅行', 'Taiwan Local'),
      _InterestItem('travel_polar', '極地旅行', 'Polar Travel'),
      _InterestItem('travel_weekend', '短途小旅行', 'Weekend Trips'),
      _InterestItem('travel_working_holiday', '打工度假', 'Working Holiday'),
    ],
  ),
  _InterestCategory(
    id: 'lifestyle', labelZh: '生活風格', labelEn: 'Lifestyle',
    items: [
      _InterestItem('life_cafe', '咖啡廳探索', 'Café Hopping'),
      _InterestItem('life_home_decor', '居家佈置', 'Home Decor'),
      _InterestItem('life_fashion', '時尚穿搭', 'Fashion'),
      _InterestItem('life_beauty', '美妝保養', 'Beauty & Skincare'),
      _InterestItem('life_wellness', '健康養生', 'Wellness'),
      _InterestItem('life_sustainability', '可持續生活', 'Sustainability'),
      _InterestItem('life_thrift', '二手古著', 'Thrift & Vintage'),
      _InterestItem('life_diy', 'DIY改造', 'DIY'),
      _InterestItem('life_aromatherapy', '香薰香氛', 'Aromatherapy'),
      _InterestItem('life_astrology', '占星塔羅', 'Astrology & Tarot'),
      _InterestItem('life_board_games', '桌遊', 'Board Games'),
      _InterestItem('life_escape_room', '密室逃脫', 'Escape Room'),
      _InterestItem('life_slow_living', '慢活', 'Slow Living'),
      _InterestItem('life_minimalism', '極簡主義', 'Minimalism'),
      _InterestItem('life_art_gallery', '美術館', 'Art Gallery'),
      _InterestItem('life_museum', '博物館', 'Museum'),
      _InterestItem('life_theatre', '劇場表演', 'Theatre'),
      _InterestItem('life_standup', '脫口秀', 'Stand-up Comedy'),
      _InterestItem('life_volunteering', '志工服務', 'Volunteering'),
    ],
  ),
  _InterestCategory(
    id: 'sports', labelZh: '運動', labelEn: 'Sports',
    items: [
      _InterestItem('sport_basketball', '籃球', 'Basketball'),
      _InterestItem('sport_soccer', '足球', 'Soccer'),
      _InterestItem('sport_badminton', '羽毛球', 'Badminton'),
      _InterestItem('sport_swimming', '游泳', 'Swimming'),
      _InterestItem('sport_running', '跑步', 'Running'),
      _InterestItem('sport_gym', '健身重訓', 'Gym & Weightlifting'),
      _InterestItem('sport_yoga', '瑜伽', 'Yoga'),
      _InterestItem('sport_hiking', '爬山登山', 'Hiking'),
      _InterestItem('sport_table_tennis', '桌球', 'Table Tennis'),
      _InterestItem('sport_tennis', '網球', 'Tennis'),
      _InterestItem('sport_baseball', '棒球', 'Baseball'),
      _InterestItem('sport_volleyball', '排球', 'Volleyball'),
      _InterestItem('sport_golf', '高爾夫', 'Golf'),
      _InterestItem('sport_skateboarding', '滑板', 'Skateboarding'),
      _InterestItem('sport_surfing', '衝浪', 'Surfing'),
      _InterestItem('sport_cycling', '騎單車', 'Cycling'),
      _InterestItem('sport_martial_arts', '格鬥武術', 'Martial Arts'),
      _InterestItem('sport_dance', '舞蹈', 'Dance'),
      _InterestItem('sport_climbing', '攀岩', 'Rock Climbing'),
      _InterestItem('sport_skiing', '滑雪', 'Skiing'),
      _InterestItem('sport_triathlon', '鐵人三項', 'Triathlon'),
      _InterestItem('sport_crossfit', 'CrossFit', 'CrossFit'),
      _InterestItem('sport_pilates', '皮拉提斯', 'Pilates'),
      _InterestItem('sport_marathon', '馬拉松', 'Marathon'),
      _InterestItem('sport_frisbee', '飛盤', 'Frisbee'),
      _InterestItem('sport_pickleball', '匹克球', 'Pickleball'),
    ],
  ),
  _InterestCategory(
    id: 'pets', labelZh: '寵物', labelEn: 'Pets',
    items: [
      _InterestItem('pet_cats', '貓咪', 'Cats'),
      _InterestItem('pet_dogs', '狗狗', 'Dogs'),
      _InterestItem('pet_rabbits', '兔子', 'Rabbits'),
      _InterestItem('pet_hamsters', '倉鼠', 'Hamsters'),
      _InterestItem('pet_birds', '鳥類', 'Birds'),
      _InterestItem('pet_fish', '觀賞魚', 'Fish'),
      _InterestItem('pet_reptiles', '爬蟲類', 'Reptiles'),
      _InterestItem('pet_guinea_pigs', '天竺鼠', 'Guinea Pigs'),
      _InterestItem('pet_hedgehogs', '刺蝟', 'Hedgehogs'),
      _InterestItem('pet_amphibians', '兩棲類', 'Amphibians'),
      _InterestItem('pet_adoption', '退役犬貓認養', 'Pet Adoption'),
      _InterestItem('pet_photography', '寵物攝影', 'Pet Photography'),
      _InterestItem('pet_walking', '寵物溜達', 'Pet Walking'),
      _InterestItem('pet_volunteering', '動物志工', 'Animal Volunteering'),
      _InterestItem('pet_zoo', '動物園', 'Zoo'),
      _InterestItem('pet_aquarium', '水族館', 'Aquarium'),
    ],
  ),
  _InterestCategory(
    id: 'artists', labelZh: '藝人', labelEn: 'Artists',
    items: [
      // 台灣
      _InterestItem('artist_jay_chou', '周杰倫', 'Jay Chou'),
      _InterestItem('artist_mayday', '五月天', 'Mayday'),
      _InterestItem('artist_jolin', '蔡依林', 'Jolin Tsai'),
      _InterestItem('artist_jj_lin', '林俊傑', 'JJ Lin'),
      _InterestItem('artist_amei', '張惠妹', 'A-mei'),
      _InterestItem('artist_eason', '陳奕迅', 'Eason Chan'),
      _InterestItem('artist_crowd_lu', '盧廣仲', 'Crowd Lu'),
      _InterestItem('artist_waa_wei', '魏如萱', 'Waa Wei'),
      _InterestItem('artist_accusefive', '告五人', 'Accusefive'),
      _InterestItem('artist_eggplant_egg', '茄子蛋', 'Eggplant Egg'),
      _InterestItem('artist_leo_wang', 'Leo王', 'Leo Wang'),
      _InterestItem('artist_9m88', '9m88', '9m88'),
      // K-pop（無中文名，zh = en）
      _InterestItem('artist_bts', 'BTS', 'BTS'),
      _InterestItem('artist_blackpink', 'BLACKPINK', 'BLACKPINK'),
      _InterestItem('artist_twice', 'TWICE', 'TWICE'),
      _InterestItem('artist_aespa', 'aespa', 'aespa'),
      _InterestItem('artist_newjeans', 'NewJeans', 'NewJeans'),
      _InterestItem('artist_ive', 'IVE', 'IVE'),
      _InterestItem('artist_seventeen', 'SEVENTEEN', 'SEVENTEEN'),
      _InterestItem('artist_stray_kids', 'Stray Kids', 'Stray Kids'),
      _InterestItem('artist_le_sserafim', 'LE SSERAFIM', 'LE SSERAFIM'),
      _InterestItem('artist_nct_dream', 'NCT DREAM', 'NCT DREAM'),
      // J-pop / J-rock
      _InterestItem('artist_kenshi_yonezu', '米津玄師', 'Kenshi Yonezu'),
      _InterestItem('artist_gen_hoshino', '星野源', 'Gen Hoshino'),
      _InterestItem('artist_hikaru_utada', '宇多田光', 'Hikaru Utada'),
      _InterestItem('artist_official_hige', 'Official髭男dism', 'Official髭男dism'),
      _InterestItem('artist_fujii_kaze', '藤井風', 'Fujii Kaze'),
      _InterestItem('artist_aimyon', 'Aimyon', 'Aimyon'),
      _InterestItem('artist_yoasobi', 'YOASOBI', 'YOASOBI'),
      _InterestItem('artist_king_gnu', 'King Gnu', 'King Gnu'),
      _InterestItem('artist_yuri', '優里', 'Yuri'),
      _InterestItem('artist_back_number', 'back number', 'back number'),
      // 西洋
      _InterestItem('artist_taylor_swift', '泰勒絲', 'Taylor Swift'),
      _InterestItem('artist_beyonce', '碧昂絲', 'Beyoncé'),
      _InterestItem('artist_the_weeknd', 'The Weeknd', 'The Weeknd'),
      _InterestItem('artist_ed_sheeran', '紅髮艾德', 'Ed Sheeran'),
      _InterestItem('artist_billie_eilish', 'Billie Eilish', 'Billie Eilish'),
      _InterestItem('artist_olivia_rodrigo', 'Olivia Rodrigo', 'Olivia Rodrigo'),
      _InterestItem('artist_harry_styles', 'Harry Styles', 'Harry Styles'),
      _InterestItem('artist_drake', 'Drake', 'Drake'),
      _InterestItem('artist_coldplay', 'Coldplay', 'Coldplay'),
      _InterestItem('artist_arctic_monkeys', 'Arctic Monkeys', 'Arctic Monkeys'),
      _InterestItem('artist_radiohead', 'Radiohead', 'Radiohead'),
      _InterestItem('artist_kendrick_lamar', 'Kendrick Lamar', 'Kendrick Lamar'),
      _InterestItem('artist_frank_ocean', 'Frank Ocean', 'Frank Ocean'),
      _InterestItem('artist_sza', 'SZA', 'SZA'),
    ],
  ),
  _InterestCategory(
    id: 'art', labelZh: '藝術創作', labelEn: 'Arts & Crafts',
    items: [
      _InterestItem('art_painting', '繪畫', 'Painting'),
      _InterestItem('art_photography', '攝影', 'Photography'),
      _InterestItem('art_songwriting', '音樂創作', 'Songwriting'),
      _InterestItem('art_writing', '寫作', 'Writing'),
      _InterestItem('art_design', '設計', 'Design'),
      _InterestItem('art_illustration', '插畫', 'Illustration'),
      _InterestItem('art_crafts', '手工藝', 'Crafts'),
      _InterestItem('art_pottery', '陶藝', 'Pottery'),
      _InterestItem('art_calligraphy', '書法', 'Calligraphy'),
      _InterestItem('art_embroidery', '刺繡', 'Embroidery'),
      _InterestItem('art_knitting', '編織', 'Knitting'),
      _InterestItem('art_sculpture', '雕塑', 'Sculpture'),
      _InterestItem('art_street_art', '街頭藝術', 'Street Art'),
      _InterestItem('art_digital', '數位藝術', 'Digital Art'),
      _InterestItem('art_video_editing', '影片剪輯', 'Video Editing'),
      _InterestItem('art_podcast', 'Podcast', 'Podcast'),
      _InterestItem('art_fashion_design', '時尚設計', 'Fashion Design'),
      _InterestItem('art_interior_design', '室內設計', 'Interior Design'),
      _InterestItem('art_floristry', '花藝', 'Floristry'),
      _InterestItem('art_leathercraft', '皮革工藝', 'Leathercraft'),
      _InterestItem('art_printmaking', '版畫', 'Printmaking'),
      _InterestItem('art_watercolor', '水彩', 'Watercolor'),
      _InterestItem('art_drawing', '素描', 'Drawing'),
    ],
  ),
  _InterestCategory(
    id: 'learning', labelZh: '學習成長', labelEn: 'Self-Growth',
    items: [
      _InterestItem('learn_reading', '閱讀', 'Reading'),
      _InterestItem('learn_language', '語言學習', 'Language Learning'),
      _InterestItem('learn_online_courses', '線上課程', 'Online Courses'),
      _InterestItem('learn_meditation', '冥想', 'Meditation'),
      _InterestItem('learn_psychology', '心理學', 'Psychology'),
      _InterestItem('learn_philosophy', '哲學', 'Philosophy'),
      _InterestItem('learn_history', '歷史', 'History'),
      _InterestItem('learn_science', '科學', 'Science'),
      _InterestItem('learn_public_speaking', '演講表達', 'Public Speaking'),
      _InterestItem('learn_time_mgmt', '時間管理', 'Time Management'),
      _InterestItem('learn_investing', '投資理財', 'Investing'),
      _InterestItem('learn_entrepreneurship', '創業', 'Entrepreneurship'),
      _InterestItem('learn_business', '商業管理', 'Business'),
      _InterestItem('learn_ted', 'TED Talks', 'TED Talks'),
      _InterestItem('learn_personal_growth', '自我成長', 'Personal Growth'),
      _InterestItem('learn_mindfulness', '正念', 'Mindfulness'),
    ],
  ),
  _InterestCategory(
    id: 'drinks', labelZh: '酒飲', labelEn: 'Drinks',
    items: [
      _InterestItem('drink_draft_beer', '生啤', 'Draft Beer'),
      _InterestItem('drink_craft_beer', '精釀啤酒', 'Craft Beer'),
      _InterestItem('drink_stout', '黑啤', 'Stout'),
      _InterestItem('drink_ipa', 'IPA', 'IPA'),
      _InterestItem('drink_wheat_beer', '小麥啤酒', 'Wheat Beer'),
      _InterestItem('drink_trappist', '比利時修道院啤酒', 'Trappist'),
      _InterestItem('drink_single_malt', '單一麥芽威士忌', 'Single Malt'),
      _InterestItem('drink_japanese_whisky', '日本威士忌', 'Japanese Whisky'),
      _InterestItem('drink_bourbon', '波本威士忌', 'Bourbon'),
      _InterestItem('drink_irish_whiskey', '愛爾蘭威士忌', 'Irish Whiskey'),
      _InterestItem('drink_blended_whisky', '調和威士忌', 'Blended Whisky'),
      _InterestItem('drink_gin', '琴酒', 'Gin'),
      _InterestItem('drink_vodka', '伏特加', 'Vodka'),
      _InterestItem('drink_rum', '蘭姆酒', 'Rum'),
      _InterestItem('drink_tequila', '龍舌蘭', 'Tequila'),
      _InterestItem('drink_brandy', '白蘭地', 'Brandy'),
      _InterestItem('drink_sake', '清酒', 'Sake'),
      _InterestItem('drink_shochu', '燒酎', 'Shochu'),
      _InterestItem('drink_plum_wine', '梅酒', 'Plum Wine'),
      _InterestItem('drink_red_wine', '紅酒', 'Red Wine'),
      _InterestItem('drink_white_wine', '白葡萄酒', 'White Wine'),
      _InterestItem('drink_natural_wine', '自然酒', 'Natural Wine'),
      _InterestItem('drink_champagne', '香檳', 'Champagne'),
      _InterestItem('drink_prosecco', '氣泡酒', 'Prosecco'),
      _InterestItem('drink_martini', '馬丁尼', 'Martini'),
      _InterestItem('drink_negroni', '內格羅尼', 'Negroni'),
      _InterestItem('drink_old_fashioned', '老式雞尾酒', 'Old Fashioned'),
      _InterestItem('drink_mojito', '莫西多', 'Mojito'),
      _InterestItem('drink_aperol_spritz', '艾普羅氣泡酒', 'Aperol Spritz'),
      _InterestItem('drink_whiskey_sour', '威士忌酸', 'Whiskey Sour'),
      _InterestItem('drink_gin_tonic', '琴通寧', 'Gin & Tonic'),
      _InterestItem('drink_long_island', 'Long Island Iced Tea', 'Long Island Iced Tea'),
      _InterestItem('drink_whisky_tasting', '威士忌品飲', 'Whisky Tasting'),
      _InterestItem('drink_mixology', '調酒課', 'Mixology Class'),
      _InterestItem('drink_wine_pairing', '葡萄酒配餐', 'Wine Pairing'),
      _InterestItem('drink_bar_hopping', '清吧小酌', 'Bar Hopping'),
      _InterestItem('drink_izakaya', '居酒屋', 'Izakaya'),
    ],
  ),
  _InterestCategory(
    id: 'tech', labelZh: '科技', labelEn: 'Tech',
    items: [
      _InterestItem('tech_coding', '程式設計', 'Coding'),
      _InterestItem('tech_ai', 'AI / 機器學習', 'AI / Machine Learning'),
      _InterestItem('tech_gaming', '遊戲', 'Gaming'),
      _InterestItem('tech_esports', '電競', 'Esports'),
      _InterestItem('tech_vr', '虛擬實境', 'VR/AR'),
      _InterestItem('tech_3d_printing', '3D列印', '3D Printing'),
      _InterestItem('tech_drones', '無人機', 'Drones'),
      _InterestItem('tech_smart_home', '智慧家庭', 'Smart Home'),
      _InterestItem('tech_crypto', '加密貨幣', 'Crypto'),
      _InterestItem('tech_news', '科技新聞', 'Tech News'),
      _InterestItem('tech_app_design', 'App設計', 'App Design'),
      _InterestItem('tech_open_source', '開源軟體', 'Open Source'),
      _InterestItem('tech_robotics', '機器人', 'Robotics'),
      _InterestItem('tech_cybersecurity', '資訊安全', 'Cybersecurity'),
    ],
  ),
];

const _kMinRequired = 5;
const _kMaxPerCategory = 50;

// ── Page ────────────────────────────────────────────────────────────────────

/// Profile Setup Step 1 — 興趣填寫
///
/// 路由：/profile-setup/interests（初次設定）或 /me/edit/interests（編輯模式）
/// 單頁滾動設計：所有類別一次呈現，頂部錨點列可跳轉至對應區塊。
/// 完成後寫入 profiles.interests（Supabase）。
/// isEditMode = false：完成後 push 到 _QuestionsPage
/// isEditMode = true：完成後 pop 回上一頁（編輯流程）
class ApplyInterestsPage extends ConsumerStatefulWidget {
  const ApplyInterestsPage({super.key, this.isEditMode = false});

  /// true → 隱藏步驟指示，儲存後直接 pop（用於個人資料編輯流程）
  final bool isEditMode;

  @override
  ConsumerState<ApplyInterestsPage> createState() => _ApplyInterestsPageState();
}

class _ApplyInterestsPageState extends ConsumerState<ApplyInterestsPage> {
  final _scrollController = ScrollController();

  /// 錨點：每個類別標題的 GlobalKey，用於計算偏移量
  final _categoryKeys = <String, GlobalKey>{
    for (final cat in _kCategories) cat.id: GlobalKey(),
  };

  /// 目前滾動位置所在的類別 id
  String _activeCategoryId = _kCategories.first.id;

  /// 錨點列 ScrollController（讓錨點列自動捲到當前項目）
  final _anchorScrollController = ScrollController();

  /// 每個錨點膠囊的 GlobalKey（用於自動捲動錨點列）
  final _anchorKeys = <String, GlobalKey>{
    for (final cat in _kCategories) cat.id: GlobalKey(),
  };

  final Map<String, Set<String>> _selectedByCategory = {
    for (final cat in _kCategories) cat.id: <String>{},
  };

  final Map<String, List<String>> _customByCategory = {
    for (final cat in _kCategories) cat.id: <String>[],
  };

  bool _isSaving = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSavedInterests();
  }

  Future<void> _loadSavedInterests() async {
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoadingInitial = false);
        return;
      }

      final row = await ref
          .read(supabaseProvider)
          .from('profiles')
          .select('interests')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      final saved = (row?['interests'] as List?)?.cast<String>() ?? [];
      if (saved.isNotEmpty) {
        setState(() {
          for (final id in saved) {
            // 用 ID 找出屬於哪個 preset 類別
            bool found = false;
            for (final cat in _kCategories) {
              if (cat.items.any((item) => item.id == id)) {
                _selectedByCategory[cat.id]!.add(id);
                found = true;
                break;
              }
            }
            // 找不到 preset ID → 視為自訂項目（顯示字串），歸入生活風格
            if (!found) {
              const fallbackId = 'lifestyle';
              _customByCategory[fallbackId]!.add(id);
              _selectedByCategory[fallbackId]!.add(id);
            }
          }
        });
      }
    } catch (_) {
      // 讀取失敗時讓用戶重新選，不阻擋頁面
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _anchorScrollController.dispose();
    super.dispose();
  }

  // ── 滾動偵測：更新 active 類別 ───────────────────────────────────────────────

  void _onScroll() {
    // 已捲到底端 → 直接激活最後一個類別（無論 header 位置）
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 2) {
      final lastId = _kCategories.last.id;
      if (_activeCategoryId != lastId) {
        setState(() => _activeCategoryId = lastId);
        _scrollAnchorIntoView(lastId);
      }
      return;
    }

    for (final cat in _kCategories.reversed) {
      final key = _categoryKeys[cat.id];
      final ctx = key?.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;

      final position = box.localToGlobal(Offset.zero);
      // 標題進入視窗上方 1/3 時視為 active
      if (position.dy <= MediaQuery.sizeOf(context).height * 0.35) {
        if (_activeCategoryId != cat.id) {
          setState(() => _activeCategoryId = cat.id);
          _scrollAnchorIntoView(cat.id);
        }
        break;
      }
    }
  }

  /// 讓錨點列自動捲到 active 項目
  void _scrollAnchorIntoView(String categoryId) {
    final key = _anchorKeys[categoryId];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.3,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ── 跳轉到類別 ───────────────────────────────────────────────────────────────

  void _jumpToCategory(String categoryId) {
    final key = _categoryKeys[categoryId];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.0,
    );
  }

  // ── 選擇邏輯 ─────────────────────────────────────────────────────────────────

  int get _totalSelected =>
      _selectedByCategory.values.fold(0, (sum, s) => sum + s.length);

  List<String> get _allSelected =>
      _selectedByCategory.values.expand((s) => s).toList();

  bool get _canProceed => _totalSelected >= _kMinRequired;

  void _toggle(String categoryId, String item) {
    final l10n = AppLocalizations.of(context)!;
    final set = _selectedByCategory[categoryId]!;
    if (set.contains(item)) {
      setState(() => set.remove(item));
    } else if (set.length < _kMaxPerCategory) {
      setState(() => set.add(item));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.applyInterestsCategoryMax(_kMaxPerCategory)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeCustomItem(String categoryId, String item) {
    setState(() {
      _customByCategory[categoryId]!.remove(item);
      _selectedByCategory[categoryId]!.remove(item);
    });
  }

  Future<void> _addCustomItem(String categoryId) async {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final controller = TextEditingController();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.pagePadding,
          right: AppSpacing.pagePadding,
          top: AppSpacing.lg,
          bottom: (MediaQuery.viewInsetsOf(ctx).bottom > MediaQuery.viewPaddingOf(ctx).bottom
                  ? MediaQuery.viewInsetsOf(ctx).bottom
                  : MediaQuery.viewPaddingOf(ctx).bottom) +
              AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.applyInterestsAddCustomTitle,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 20,
              style: Theme.of(ctx)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.primaryText),
              decoration: InputDecoration(
                hintText: l10n.applyInterestsAddCustomHint,
                hintStyle: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                      color: colors.secondaryText.withValues(alpha: 0.6),
                    ),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                filled: true,
                fillColor: colors.backgroundWarm,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide:
                      BorderSide(color: colors.forestGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LukoButton.primary(
              label: l10n.applyInterestsAddButton,
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) Navigator.pop(ctx, text);
              },
            ),
          ],
        ),
      ),
    );

    if (result == null || result.isEmpty || !mounted) return;

    final set = _selectedByCategory[categoryId]!;
    if (set.length >= _kMaxPerCategory) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.applyInterestsCategoryMax(_kMaxPerCategory),
            ),
          ),
        );
      }
      return;
    }

    final isDuplicate = set.contains(result) ||
        _kCategories.any((c) =>
            c.id == categoryId &&
            c.items.any((item) => item.zh == result || item.en == result));
    if (isDuplicate) return;

    setState(() {
      _customByCategory[categoryId]!.add(result);
      set.add(result);
    });
  }

  // ── 儲存 ─────────────────────────────────────────────────────────────────────

  Future<void> _proceed() async {
    if (!_canProceed || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      await ref
          .read(supabaseProvider)
          .from('profiles')
          .update({'interests': _allSelected}).eq('id', userId);

      if (!mounted) return;

      if (widget.isEditMode) {
        // 編輯模式：儲存後直接返回
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ApplyQuestionsPage(),
            settings: const RouteSettings(name: '/profile-setup/questions'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.commonError)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final total = _totalSelected;

    if (_isLoadingInitial) {
      return Scaffold(
        backgroundColor: colors.backgroundWarm,
        body: Center(
          child: CircularProgressIndicator(color: colors.forestGreen),
        ),
      );
    }

    return LukoLoadingOverlay(
      isLoading: _isSaving,
      message: l10n.commonSaving,
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 固定頂部區：步驟、標題、計數、錨點列 ─────────────────────
              _TopHeader(
                total: total,
                minRequired: _kMinRequired,
                canProceed: _canProceed,
                activeCategoryId: _activeCategoryId,
                categories: _kCategories,
                anchorKeys: _anchorKeys,
                anchorScrollController: _anchorScrollController,
                onAnchorTap: _jumpToCategory,
                colors: colors,
                textTheme: textTheme,
                isEditMode: widget.isEditMode,
              ),

              // ── 可滾動內容：所有類別連續顯示 ─────────────────────────────
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    for (final cat in _kCategories)
                      _CategorySection(
                        category: cat,
                        categoryKey: _categoryKeys[cat.id]!,
                        selected: _selectedByCategory[cat.id]!,
                        customItems: _customByCategory[cat.id]!,
                        colors: colors,
                        textTheme: textTheme,
                        onToggle: (item) => _toggle(cat.id, item),
                        onAddCustom: () => _addCustomItem(cat.id),
                        onRemoveCustom: (item) =>
                            _removeCustomItem(cat.id, item),
                      ),
                    // 底部留白：清除底部按鈕遮擋
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxxl),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── 底部按鈕 ────────────────────────────────────────────────────────
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_canProceed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      l10n.applyInterestsShortfall(_kMinRequired - total),
                      style: textTheme.bodySmall
                          ?.copyWith(color: colors.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ),
                LukoButton.primary(
                  label: widget.isEditMode ? l10n.commonSave : l10n.commonNext,
                  onPressed: _canProceed ? _proceed : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 固定頂部（步驟 + 標題 + 錨點列）────────────────────────────────────────────

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.total,
    required this.minRequired,
    required this.canProceed,
    required this.activeCategoryId,
    required this.categories,
    required this.anchorKeys,
    required this.anchorScrollController,
    required this.onAnchorTap,
    required this.colors,
    required this.textTheme,
    this.isEditMode = false,
  });

  final int total;
  final int minRequired;
  final bool canProceed;
  final String activeCategoryId;
  final List<_InterestCategory> categories;
  final Map<String, GlobalKey> anchorKeys;
  final ScrollController anchorScrollController;
  final ValueChanged<String> onAnchorTap;
  final AppColors colors;
  final TextTheme textTheme;
  final bool isEditMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: colors.backgroundWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 步驟指示（編輯模式下隱藏）
          if (!isEditMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding, AppSpacing.md,
                AppSpacing.pagePadding, 0,
              ),
              child: Text(
                l10n.applyStep(1, 2),
                style: textTheme.labelMedium
                    ?.copyWith(color: colors.secondaryText),
                textAlign: TextAlign.center,
              ),
            ),

          // 標題 + 已選計數
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding, AppSpacing.md,
              AppSpacing.pagePadding, AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.applyInterestsTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.applyInterestsSubtitle(minRequired),
                        style: textTheme.bodySmall
                            ?.copyWith(color: colors.secondaryText),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: canProceed
                        ? colors.forestGreenSubtle
                        : colors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: canProceed
                          ? colors.forestGreen.withValues(alpha: 0.5)
                          : colors.divider,
                    ),
                  ),
                  child: Text(
                    l10n.applyInterestsSelected(total),
                    style: textTheme.labelMedium?.copyWith(
                      color: canProceed
                          ? colors.forestGreen
                          : colors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 錨點膠囊列
          SizedBox(
            height: 36,
            child: ListView.separated(
              controller: anchorScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isActive = cat.id == activeCategoryId;
                return _AnchorPill(
                  key: anchorKeys[cat.id],
                  label: cat.label(context),
                  isActive: isActive,
                  colors: colors,
                  onTap: () => onAnchorTap(cat.id),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // 分隔線
          Divider(height: 1, thickness: 1, color: colors.divider),
        ],
      ),
    );
  }
}

// ── 錨點膠囊 ─────────────────────────────────────────────────────────────────

class _AnchorPill extends StatelessWidget {
  const _AnchorPill({
    super.key,
    required this.label,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colors.forestGreen : colors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? colors.forestGreen
                : colors.divider,
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isActive ? colors.brandOnDark : colors.secondaryText,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── 類別區塊（Sliver）────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.categoryKey,
    required this.selected,
    required this.customItems,
    required this.colors,
    required this.textTheme,
    required this.onToggle,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  final _InterestCategory category;
  final GlobalKey categoryKey;
  final Set<String> selected;
  final List<String> customItems;
  final AppColors colors;
  final TextTheme textTheme;
  final ValueChanged<String> onToggle;
  final VoidCallback onAddCustom;
  final ValueChanged<String> onRemoveCustom;

  @override
  Widget build(BuildContext context) {
    final count = selected.length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.xl,
          AppSpacing.pagePadding,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 類別標題行：名稱 + 已選數量
            Row(
              key: categoryKey,
              children: [
                Text(
                  category.label(context),
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.forestGreenSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.forestGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Chip Wrap
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ...category.items.map((item) {
                  final isSelected = selected.contains(item.id);
                  return _InterestChip(
                    label: item.label(context),
                    isSelected: isSelected,
                    colors: colors,
                    onTap: () => onToggle(item.id),
                  );
                }),
                // 自訂項目：顯示 × 按鈕以完整移除
                ...customItems.map((item) {
                  final isSelected = selected.contains(item);
                  return _CustomInterestChip(
                    label: item,
                    isSelected: isSelected,
                    colors: colors,
                    onTap: () => onToggle(item),
                    onRemove: () => onRemoveCustom(item),
                  );
                }),
                _AddChip(colors: colors, onTap: onAddCustom),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Interest Chip ─────────────────────────────────────────────────────────────

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.forestGreenSubtle : colors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.forestGreen.withValues(alpha: 0.7)
                : colors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color:
                isSelected ? colors.forestGreen : colors.primaryText,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Custom Interest Chip（帶 × 移除按鈕）────────────────────────────────────────

class _CustomInterestChip extends StatelessWidget {
  const _CustomInterestChip({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8, right: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.forestGreenSubtle : colors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colors.forestGreen.withValues(alpha: 0.7)
                : colors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: isSelected ? colors.forestGreen : colors.primaryText,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isSelected
                      ? colors.forestGreen
                      : colors.secondaryText.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Chip ──────────────────────────────────────────────────────────────────

class _AddChip extends StatelessWidget {
  const _AddChip({required this.colors, required this.onTap});

  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: colors.secondaryText),
            const SizedBox(width: 4),
            Text(
              '新增',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Questions Page
// ═════════════════════════════════════════════════════════════════════════════

class _QuestionItem {
  const _QuestionItem({required this.id, required this.text});
  final String id;
  final String text;
}

class _QuestionCategory {
  const _QuestionCategory({
    required this.id,
    required this.label,
    required this.questions,
  });
  final String id;
  final String label;
  final List<_QuestionItem> questions;
}

const _kQuestionCategories = [
  _QuestionCategory(
    id: 'daily',
    label: '日常生活',
    questions: [
      _QuestionItem(id: 'daily_1', text: '你是早起型還是夜貓子？'),
      _QuestionItem(id: 'daily_2', text: '描述你理想的週末是什麼樣子？'),
      _QuestionItem(id: 'daily_3', text: '你早餐通常吃什麼？'),
      _QuestionItem(id: 'daily_4', text: '工作日的你和假日的你，最大的差別是？'),
      _QuestionItem(id: 'daily_5', text: '你在家最喜歡做什麼？'),
      _QuestionItem(id: 'daily_6', text: '你是整理控還是享受微亂的人？'),
      _QuestionItem(id: 'daily_7', text: '你一天沒有哪件事不行？'),
    ],
  ),
  _QuestionCategory(
    id: 'food',
    label: '飲食品味',
    questions: [
      _QuestionItem(id: 'food_1', text: '你喜歡自己煮還是出去吃？'),
      _QuestionItem(id: 'food_2', text: '你有沒有一道會煮的拿手菜？'),
      _QuestionItem(id: 'food_3', text: '最近讓你念念不忘的一道料理是？'),
      _QuestionItem(id: 'food_4', text: '你對食物有什麼特別的堅持或偏好？'),
      _QuestionItem(id: 'food_5', text: '你覺得一起吃飯最重要的是？'),
      _QuestionItem(id: 'food_6', text: '你對咖啡或手搖飲有什麼儀式感嗎？'),
    ],
  ),
  _QuestionCategory(
    id: 'travel',
    label: '旅行',
    questions: [
      _QuestionItem(id: 'travel_1', text: '你旅行時更喜歡計畫好一切，還是隨性出發？'),
      _QuestionItem(id: 'travel_2', text: '到目前為止最難忘的旅行是哪一次？'),
      _QuestionItem(id: 'travel_3', text: '你的清單上有哪個地方一定要去？'),
      _QuestionItem(id: 'travel_4', text: '你喜歡城市旅行還是自然旅行？'),
      _QuestionItem(id: 'travel_5', text: '如果可以一個人去旅行一個月，你會選哪裡？'),
    ],
  ),
  _QuestionCategory(
    id: 'relationship',
    label: '感情觀',
    questions: [
      _QuestionItem(id: 'rel_1', text: '你認為愛情裡最重要的一件事是什麼？'),
      _QuestionItem(id: 'rel_2', text: '你的愛之語是哪一種？'),
      _QuestionItem(id: 'rel_3', text: '你喜歡每天保持聯繫，還是各自有空間的相處模式？'),
      _QuestionItem(id: 'rel_4', text: '你覺得兩個人「合適」的關鍵是什麼？'),
      _QuestionItem(id: 'rel_5', text: '你理想中的第一次約會是什麼樣子？'),
    ],
  ),
  _QuestionCategory(
    id: 'pace',
    label: '生活步調',
    questions: [
      _QuestionItem(id: 'pace_1', text: '你偏向快節奏還是慢生活？'),
      _QuestionItem(id: 'pace_2', text: '你如何在忙碌中讓自己放鬆？'),
      _QuestionItem(id: 'pace_3', text: '你面對壓力的方式是什麼？'),
      _QuestionItem(id: 'pace_4', text: '你的社交電量能撐多久？'),
      _QuestionItem(id: 'pace_5', text: '你更享受熱鬧的社交場合，還是安靜的兩人相處？'),
    ],
  ),
  _QuestionCategory(
    id: 'values',
    label: '價值觀',
    questions: [
      _QuestionItem(id: 'val_1', text: '你人生目前最在乎的一件事是什麼？'),
      _QuestionItem(id: 'val_2', text: '你對「成功」的定義是什麼？'),
      _QuestionItem(id: 'val_3', text: '你覺得金錢在生活中扮演什麼角色？'),
      _QuestionItem(id: 'val_4', text: '你有沒有什麼事情是絕對不願意妥協的？'),
      _QuestionItem(id: 'val_5', text: '你覺得善良和能力，哪個更重要？'),
    ],
  ),
  _QuestionCategory(
    id: 'family',
    label: '家庭與未來',
    questions: [
      _QuestionItem(id: 'fam_1', text: '你對婚姻的想法是什麼？'),
      _QuestionItem(id: 'fam_2', text: '你想不想要孩子？'),
      _QuestionItem(id: 'fam_3', text: '你希望五年後自己的生活是什麼樣子？'),
      _QuestionItem(id: 'fam_4', text: '你和家人的關係是怎麼樣的？'),
      _QuestionItem(id: 'fam_5', text: '你理想中的「家」是什麼感覺？'),
    ],
  ),
  _QuestionCategory(
    id: 'personality',
    label: '個性特質',
    questions: [
      _QuestionItem(id: 'per_1', text: '用三個詞形容你自己？'),
      _QuestionItem(id: 'per_2', text: '你的朋友會怎麼描述你？'),
      _QuestionItem(id: 'per_3', text: '你是計畫型還是隨興型的人？'),
      _QuestionItem(id: 'per_4', text: '你在什麼時候最有活力？'),
      _QuestionItem(id: 'per_5', text: '你覺得自己最大的優點和缺點是什麼？'),
    ],
  ),
  _QuestionCategory(
    id: 'fun',
    label: '輕鬆有趣',
    questions: [
      _QuestionItem(id: 'fun_1', text: '如果今晚可以做任何事，你會選擇什麼？'),
      _QuestionItem(id: 'fun_2', text: '你有什麼讓人意外的冷知識或技能？'),
      _QuestionItem(id: 'fun_3', text: '你最近笑得最開心的一次是什麼？'),
      _QuestionItem(id: 'fun_4', text: '如果你是一道料理，你會是什麼？'),
      _QuestionItem(id: 'fun_5', text: '你有什麼獨特的小怪癖嗎？'),
      _QuestionItem(id: 'fun_6', text: '如果可以和任何一個歷史人物吃飯，你選誰？'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────

/// 個人問答頁
///
/// 路由：/profile-setup/questions（初次設定）或 /me/edit/questions（編輯模式）
/// isEditMode = true → 儲存後 pop 回上一頁；false → invalidate appUserStatusProvider
class ApplyQuestionsPage extends ConsumerStatefulWidget {
  const ApplyQuestionsPage({super.key, this.isEditMode = false});

  /// true → 儲存後直接 pop（用於個人資料編輯流程）
  final bool isEditMode;

  @override
  ConsumerState<ApplyQuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends ConsumerState<ApplyQuestionsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, String> _answers = {};
  bool _isSaving = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _kQuestionCategories.length, vsync: this);
    _loadSavedAnswers();
  }

  Future<void> _loadSavedAnswers() async {
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoadingInitial = false);
        return;
      }

      final row = await ref
          .read(supabaseProvider)
          .from('profiles')
          .select('question_answers')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      final saved = (row?['question_answers'] as List?) ?? [];
      if (saved.isNotEmpty) {
        setState(() {
          for (final item in saved) {
            final map = item as Map<String, dynamic>;
            final id = map['id'] as String?;
            final answer = map['answer'] as String?;
            if (id != null && answer != null && answer.isNotEmpty) {
              _answers[id] = answer;
            }
          }
        });
      }
    } catch (_) {
      // 讀取失敗時讓用戶重新填寫
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _answeredInCategory(String categoryId) {
    final cat = _kQuestionCategories.firstWhere((c) => c.id == categoryId);
    return cat.questions.where((q) => _answers.containsKey(q.id)).length;
  }

  Future<void> _openAnswerSheet(_QuestionItem question) async {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final existing = _answers[question.id] ?? '';
    final controller = TextEditingController(text: existing);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.pagePadding,
          right: AppSpacing.pagePadding,
          top: AppSpacing.lg,
          bottom: (MediaQuery.viewInsetsOf(ctx).bottom > MediaQuery.viewPaddingOf(ctx).bottom
                  ? MediaQuery.viewInsetsOf(ctx).bottom
                  : MediaQuery.viewPaddingOf(ctx).bottom) +
              AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              question.text,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 5,
              minLines: 3,
              maxLength: 200,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: Theme.of(ctx)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.primaryText),
              decoration: InputDecoration(
                hintText: l10n.applyQuestionsAnswerHint,
                hintStyle: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                      color:
                          colors.secondaryText.withValues(alpha: 0.6),
                    ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                filled: true,
                fillColor: colors.backgroundWarm,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide:
                      BorderSide(color: colors.forestGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (existing.isNotEmpty) ...[
                  Expanded(
                    child: LukoButton.secondary(
                      label: l10n.applyQuestionsAnswerClear,
                      onPressed: () => Navigator.pop(ctx, ''),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: LukoButton.primary(
                    label: l10n.applyQuestionsAnswerSave,
                    onPressed: () =>
                        Navigator.pop(ctx, controller.text.trim()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      if (result.isEmpty) {
        _answers.remove(question.id);
      } else {
        _answers[question.id] = result;
      }
    });
  }

  Future<void> _finish() async {
    if (_answers.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      final jsonAnswers = _answers.entries.map((e) {
        String questionText = '';
        for (final cat in _kQuestionCategories) {
          final match =
              cat.questions.where((q) => q.id == e.key).firstOrNull;
          if (match != null) {
            questionText = match.text;
            break;
          }
        }
        return {
          'id': e.key,
          'question': questionText,
          'answer': e.value,
        };
      }).toList();

      await ref
          .read(supabaseProvider)
          .from('profiles')
          .update({'question_answers': jsonAnswers}).eq('id', userId);

      if (!mounted) return;

      if (widget.isEditMode) {
        // 編輯模式：直接 pop 回個人資料編輯頁
        Navigator.of(context).pop();
      } else {
        // 初次設定：觸發 router redirect 導向主 App
        ref.invalidate(appUserStatusProvider);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.commonError),
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final canFinish = _answers.isNotEmpty;

    if (_isLoadingInitial) {
      return Scaffold(
        backgroundColor: colors.backgroundWarm,
        body: Center(
          child: CircularProgressIndicator(color: colors.forestGreen),
        ),
      );
    }

    return LukoLoadingOverlay(
      isLoading: _isSaving,
      message: l10n.commonSaving,
      child: Scaffold(
        backgroundColor: colors.backgroundWarm,
        appBar: AppBar(
          backgroundColor: colors.backgroundWarm,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: widget.isEditMode
              ? Text(
                  '個人問答',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  l10n.applyStep(2, 2),
                  style: textTheme.labelMedium
                      ?.copyWith(color: colors.secondaryText),
                ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: _QuestionTabBar(
              controller: _tabController,
              categories: _kQuestionCategories,
              answeredInCategory: _answeredInCategory,
              colors: colors,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.applyQuestionsTitle,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.applyQuestionsSubtitle,
                          style: textTheme.bodySmall
                              ?.copyWith(color: colors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: canFinish
                          ? colors.forestGreenSubtle
                          : colors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: canFinish
                            ? colors.forestGreen.withValues(alpha: 0.5)
                            : colors.divider,
                      ),
                    ),
                    child: Text(
                      l10n.applyQuestionsAnswered(_answers.length),
                      style: textTheme.labelMedium?.copyWith(
                        color: canFinish
                            ? colors.forestGreen
                            : colors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _kQuestionCategories.map((cat) {
                  return _QuestionList(
                    category: cat,
                    answers: _answers,
                    colors: colors,
                    onTap: _openAnswerSheet,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!canFinish)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      l10n.applyQuestionsMinRequired,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colors.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ),
                LukoButton.primary(
                  label: widget.isEditMode ? l10n.commonSave : l10n.applyVerifyDone,
                  onPressed: canFinish ? _finish : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Question Tab Bar ──────────────────────────────────────────────────────────

class _QuestionTabBar extends StatelessWidget {
  const _QuestionTabBar({
    required this.controller,
    required this.categories,
    required this.answeredInCategory,
    required this.colors,
  });

  final TabController controller;
  final List<_QuestionCategory> categories;
  final int Function(String categoryId) answeredInCategory;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: colors.divider,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colors.forestGreen, width: 2.5),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(2)),
      ),
      labelColor: colors.forestGreen,
      unselectedLabelColor: colors.secondaryText,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      tabs: categories.map((cat) {
        final count = answeredInCategory(cat.id);
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cat.label),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.forestGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.brandOnDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Question List ─────────────────────────────────────────────────────────────

class _QuestionList extends StatelessWidget {
  const _QuestionList({
    required this.category,
    required this.answers,
    required this.colors,
    required this.onTap,
  });

  final _QuestionCategory category;
  final Map<String, String> answers;
  final AppColors colors;
  final ValueChanged<_QuestionItem> onTap;

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView + Column：讓 TabBarView（PageView）完整接管橫滑手勢，
    // 垂直捲動只在內容超出螢幕時才介入，減少手勢搶奪。
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          for (int i = 0; i < category.questions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Builder(builder: (context) {
              final question = category.questions[i];
              final answered = answers[question.id];
              final hasAnswer = answered != null && answered.isNotEmpty;
              return _QuestionCard(
                question: question,
                answer: answered,
                hasAnswer: hasAnswer,
                colors: colors,
                onTap: () => onTap(question),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Question Card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.answer,
    required this.hasAnswer,
    required this.colors,
    required this.onTap,
  });

  final _QuestionItem question;
  final String? answer;
  final bool hasAnswer;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:
              hasAnswer ? colors.forestGreenSubtle : colors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: hasAnswer
                ? colors.forestGreen.withValues(alpha: 0.5)
                : colors.divider,
            width: hasAnswer ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasAnswer) ...[
                    const SizedBox(height: 6),
                    Text(
                      answer!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.forestGreen,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              hasAnswer
                  ? Icons.edit_outlined
                  : Icons.add_circle_outline,
              size: 20,
              color: hasAnswer
                  ? colors.forestGreen
                  : colors.secondaryText.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
