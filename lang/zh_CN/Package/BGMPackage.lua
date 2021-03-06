-- translation for Board Game Magazine Package

return {
	["BGM"] = "☆SP",

	["#bgm_zhaoyun"] = "白马先锋",
	["bgm_zhaoyun"] = "☆SP赵云",
	["&bgm_zhaoyun"] = "赵云",
	["illustrator:bgm_zhaoyun"] = "Vincent",
	["designer:bgm_zhaoyun"] = "Danny",
	["chongzhen"] = "冲阵",
	[":chongzhen"] = "每当你发动“龙胆”使用一张手牌指定目标后，或打出一张手牌时，你可以获得对方的一张手牌。",

	["#bgm_diaochan"] = "暗黑的傀儡师",
	["bgm_diaochan"] = "☆SP貂蝉",
	["&bgm_diaochan"] = "貂蝉",
	["illustrator:bgm_diaochan"] = "木美人",
	["designer:bgm_diaochan"] = "Danny",
	["lihun"] = "离魂",
	[":lihun"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张牌将武将牌翻面，然后获得一名男性角色的所有手牌，且出牌阶段结束时，你交给该角色X张牌。（X为该角色的体力值）",
	["LihunGoBack"] = "请交给目标角色 %arg 张牌",

	["#bgm_caoren"] = "险不辞难",
	["bgm_caoren"] = "☆SP曹仁",
	["&bgm_caoren"] = "曹仁",
	["illustrator:bgm_caoren"] = "张帅",
	["designer:bgm_caoren"] = "Danny",
	["kuiwei"] = "溃围",
	[":kuiwei"] = "结束阶段开始时，你可以摸X+2张牌，然后将你的武将牌翻面，且你的下个摸牌阶段开始时，你弃置X张牌。（X为场上武器牌的数量）",
	["@kuiwei"] = "溃围",
	["yanzheng"] = "严整",
	[":yanzheng"] = "若你的手牌数大于你的体力值，你可以将一张装备区的装备牌当【无懈可击】使用。",
	["#KuiweiDiscard"] = "%from 的“%arg2”效果被触发，须弃置 %arg 张牌";

	["#bgm_pangtong"] = "荆楚之高俊",
	["bgm_pangtong"] = "☆SP庞统",
	["&bgm_pangtong"] = "庞统",
	["illustrator:bgm_pangtong"] = "LiuHeng",
	["designer:bgm_pangtong"] = "Danny",
	["manjuan"] = "漫卷",
	[":manjuan"] = "每当你将获得一张手牌时，你将之置入弃牌堆。若你的回合内你发动“漫卷”，你可以获得弃牌堆中一张与该牌同点数的牌（不能发动“漫卷”）。",
	["zuixiang"] = "醉乡",
	[":zuixiang"] = "<font color=\"red\"><b>限定技，</b></font>准备阶段开始时，你可以将牌堆顶的三张牌置于你的武将牌上。此后每个准备阶段开始时，你重复此流程，直到你的武将牌上出现同点数的“醉乡牌”，然后你获得所有“醉乡牌”（不能发动“漫卷”）。你不能使用或打出“醉乡牌”中存在的类别的牌，且这些类别的牌对你无效。",
	["@sleep"] = "醉乡",
	["dream"] = "醉乡",
	["$ZuixiangAnimate"] = "image=image/animate/zuixiang.png",
	["$ManjuanGot"] = "%from 即将获得 %card 并将该牌置入弃牌堆",
	["#ZuiXiang1"] = "%from 的“%arg2”效果被触发， %to 的卡牌【%arg】对其无效",
	["#ZuiXiang2"] = "%from 的“%arg2”效果被触发，【%arg】对其无效",
	["$ZuixiangGot"] = "%from “醉乡牌”中有重复点数，获得所有“醉乡牌”：%card",

	["#bgm_zhangfei"] = "横矛立马",
	["bgm_zhangfei"] = "☆SP张飞",
	["&bgm_zhangfei"] = "张飞",
	["illustrator:bgm_zhangfei"] = "绿豆粥",
	["designer:bgm_zhangfei"] = "Serendipity",
	["jie"] = "嫉恶",
	[":jie"] = "<font color=\"blue\"><b>锁定技，</b></font>你使用红色【杀】对目标角色造成伤害时，此伤害+1。",
	["dahe"] = "大喝",
	[":dahe"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名角色拼点：若你赢，你可以将该角色的拼点牌交给一名体力值不多于你的角色，本回合该角色使用的非<font color=\"red\">♥</font>【闪】无效；若你没赢，你展示所有手牌，然后弃置一张手牌。",
	["@dahe-give"] = "你可以将拼点牌交给一名体力值不多于你的角色",
	["#Jie"] = "%from 的“<font color=\"yellow\"><b>嫉恶</b></font>”效果被触发，伤害从 %arg 点增加至 %arg2 点",
	["#DaheEffect"] = "%from 的“%arg2”效果被触发，%to 使用的 %arg 【<font color=\"yellow\"><b>闪</b></font>】无效",

	["#bgm_lvmeng"] = "国士之风",
	["bgm_lvmeng"] = "☆SP吕蒙",
	["&bgm_lvmeng"] = "吕蒙",
	["illustrator:bgm_lvmeng"] = "YellowKiss",
	["designer:bgm_lvmeng"] = "如水法师卞程",
	["tanhu"] = "探虎",
	[":tanhu"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名角色拼点：若你赢，你无视与该角色的距离，你使用的非延时锦囊牌对该角色结算时不能被【无懈可击】响应，直到回合结束。",
	["mouduan"] = "谋断",
	[":mouduan"] = "游戏开始时，你获得一枚“文/武”标记且“武”朝上。若你的手牌数小于或等于2，你的标记为“文”朝上。其他角色的回合开始时，若“文”朝上，你可以弃置一张牌：若如此做，你将标记翻至“武”朝上。若“武”朝上，你拥有“谦逊”和“激昂”；若“文”朝上，你拥有“英姿”和“克己”。",
	["@mouduan"] = "你可以弃置一张牌将标记翻至“武”朝上（若你的手牌数小于或等于2则无事发生）",
	["@wen"] = "文",
	["@wu"] = "武",

	["#bgm_liubei"] = "汉昭烈帝",
	["bgm_liubei"] = "☆SP刘备",
	["&bgm_liubei"] = "刘备",
	["illustrator:bgm_liubei"] = "Fool头",
	["designer:bgm_liubei"] = "妄想线条",
	["zhaolie"] = "昭烈",
	[":zhaolie"] = "摸牌阶段，你可以少摸一张牌，令你攻击范围内的一名其他角色展示牌堆顶的三张牌，将其中的非基本牌和【桃】置入弃牌堆，然后选择一项：1.令你对其造成X点伤害，然后该角色获得其余的牌；2.该角色弃置X张牌，然后你获得其余的牌。（X为其中非基本牌的数量）",
	["zhaolie_obtain:obtain"] = "你可以点击确定令 %src 获得“昭烈”牌，否则你获得这些牌",
	["@zhaolie-discard"] = "你可以弃置 %arg 张牌令 %src 获得“昭烈”牌，否则你受到 %arg 点伤害并获得这些牌",
	["zhaolie-invoke"] = "你可以发动“昭烈”<br> <b>操作提示</b>: 选择攻击范围内的一名其他角色→点击确定<br/>",
	["shichou"] = "誓仇",
	[":shichou"] = "<font color=\"orange\"><b>主公技，</b></font><font color=\"red\"><b>限定技，</b></font>准备阶段开始时，你可以交给一名其他蜀势力角色两张牌。每当你受到伤害时，你将此伤害转移给该角色，此伤害结算后该角色摸X张牌，直到其第一次进入濒死状态时。（X为伤害点数）",
	["@hate"] = "誓仇",
	["@hate_to"] = "誓仇",
	["@shichou-give"] = "你可以发动“誓仇”",
	["~shichou"] = "选择两张牌→选择一名其他蜀势力角色→点击确定",
	["$ShichouAnimate"] = "image=image/animate/shichou.png",
	["#ShichouProtect"] = "%from 的“%arg”被触发，将伤害转移给 %to ",

	["#bgm_daqiao"] = "韶光易逝",
	["bgm_daqiao"] = "☆SP大乔",
	["&bgm_daqiao"] = "大乔",
	["illustrator:bgm_daqiao"] = "木美人",
	["designer:bgm_daqiao"] = "ECauchy",
	["yanxiao"] = "言笑",
	[":yanxiao"] = "出牌阶段，你可以将一张<font color=\"red\">♦</font>牌置于一名角色的判定区内，称为“言笑牌”。判定区内有“言笑牌”的角色的判定阶段开始时获得其判定区内所有牌。",
	["YanxiaoCard"] = "言笑牌",
	["anxian"] = "安娴",
	[":anxian"] = "每当你使用【杀】对目标角色造成伤害时，你可以防止此伤害，令该角色弃置一张手牌，然后你摸一张牌。每当你被指定为【杀】的目标时，你可以弃置一张手牌，然后此【杀】的使用者摸一张牌，此【杀】对你无效。",
	["@anxian-discard"] = "你可以弃置一张手牌令此【杀】对你无效",
	["$YanxiaoGot"] = "%from 判定阶段开始时，获得其判定区内所有牌：%card",
	["#Anxian"] = "%from 发动了“%arg”，防止此伤害",
	["#AnxianAvoid"] = "%to 的“%arg”效果被触发，%from 对其使用的【<font color=\"yellow\"><b>杀</b></font>】无效",

	["#bgm_ganning"] = "怀铃的乌羽",
	["bgm_ganning"] = "☆SP甘宁",
	["&bgm_ganning"] = "甘宁",
	["illustrator:bgm_ganning"] = "张帅",
	["designer:bgm_ganning"] = "飞雪",
	["yinling"] = "银铃",
	[":yinling"] = "出牌阶段，若“锦”的数量少于四张，你可以弃置一张黑色牌，将一名其他角色的一张牌置于你的武将牌上，称为“锦”。",
	["brocade"] = "锦",
	["junwei"] = "军威",
	[":junwei"] = "结束阶段开始时，你可以将三张“锦”置入弃牌堆并选择一名角色，令该角色选择一项：1.展示一张【闪】并将该【闪】交给由你选择的一名角色；2.失去1点体力，然后你将其装备区的一张牌移出游戏，该角色的回合结束后，将这张装备牌移回其装备区。",
	["junwei-invoke"] = "你可以发动“军威”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["junwei_equip"] = "军威",
	["@junwei-show"] = "请展示一张【闪】",
	["@junwei-give"] = "你可以将该【闪】交给一名角色",
	["$JunweiGot"] = "%from 的装备牌 %card 被移回装备区",

	["#bgm_xiahoudun"] = "啖睛的苍狼",
	["bgm_xiahoudun"] = "☆SP夏侯惇",
	["&bgm_xiahoudun"] = "夏侯惇",
	["illustrator:bgm_xiahoudun"] = "XXX",
	["designer:bgm_xiahoudun"] = "舟亢",
	["fenyong"] = "愤勇",
	[":fenyong"] = "每当你受到伤害后，你可以竖置你的体力牌。每当你受到伤害时，若你的体力牌处于竖置状态，防止此伤害。",
	["@fenyong"] = "愤勇",
	["xuehen"] = "雪恨",
	[":xuehen"] = "<font color=\"blue\"><b>锁定技，</b></font>一名角色的结束阶段开始时，若你的体力牌处于竖置状态，你横置之，然后选择一项：1.弃置当前回合角色X张牌。 2.视为你使用一张无距离限制的【杀】。（X为你已损失的体力值）",
	["xuehen:discard"] = "弃置当前回合角色X张牌",
	["xuehen:slash"] = "视为使用一张【杀】",
	["#FenyongAvoid"] = "%from 的“%arg”被触发，防止了本次伤害",

	["BGMDIY"] = "桌游志贴纸",

	["#diy_simazhao"] = "狼子野心",
	["diy_simazhao"] = "司马昭",
	["illustrator:diy_simazhao"] = "YellowKiss",
	["designer:diy_simazhao"] = "尹昭晨",
	["zhaoxin"] = "昭心",
	[":zhaoxin"] = "摸牌阶段结束时，你可以展示所有手牌，视为你使用一张【杀】。",
	["@zhaoxin"] = "你可以发动“昭心”",
	["~zhaoxin"] = "选择【杀】的目标角色→点击确定",
	["langgu"] = "狼顾",
	[":langgu"] = "每当你受到1点伤害后，你可以进行判定且你可以打出一张手牌代替此判定牌，然后你观看伤害来源的所有手牌，弃置其中任意数量的与判定牌花色相同的牌。",
	["@langgu-card"] = CommonTranslationTable["@askforretrial"],
	["~langgu"] = "选择一张手牌→点击确定",

	["#diy_wangyuanji"] = "文明皇后",
	["diy_wangyuanji"] = "王元姬",
	["illustrator:diy_wangyuanji"] = "YellowKiss",
	["designer:diy_wangyuanji"] = "尹昭晨",
	["fuluan"] = "扶乱",
	[":fuluan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>若你未于本阶段使用过【杀】，你可以弃置三张相同花色的牌，令你攻击范围内的一名其他角色将武将牌翻面，然后你不能使用【杀】直到回合结束。",
	["shude"] = "淑德",
	[":shude"] = "结束阶段开始时，你可以将手牌数补至等于体力上限的张数。",

	["#diy_liuxie"] = "汉献帝",
	["diy_liuxie"] = "刘协-贴纸",
	["&diy_liuxie"] = "刘协",
	["illustrator:diy_liuxie"] = "XXX",
	["designer:diy_liuxie"] = "姚以轩",
	["huangen"] = "皇恩",
	[":huangen"] = "每当一张锦囊牌指定了至少两名目标后，你可以令至多X名角色各摸一张牌，然后该锦囊牌对这些角色无效。（X为你的体力值）",
	["hantong"] = "汉统",
	[":hantong"] = "弃牌阶段，你可以将你弃置的手牌置于武将牌上，称为“诏”。你可以将一张“诏”置入弃牌堆，然后你拥有并发动以下技能之一：“护驾”、“激将”、“救援”、“血裔”，直到回合结束。",
	["edict"] = "诏",
	["@huangen-card"] = "你可以发动“皇恩”",
	["~huangen"] = "选择至多X名角色→点击确定（X为你的体力值）",
	["hantong_acquire"] = "汉统",
	["hantong_acquire:hujia"] = "你可以发动“汉统”并获得“护驾”",
	["hantong_acquire:jijiang"] = "你可以发动“汉统”并获得“激将”",
	["hantong_acquire:jiuyuan"] = "你可以发动“汉统”并获得“救援”",
	["hantong_acquire:xueyi"] = "你可以发动“汉统”并获得“血裔”",
	["@hantong-jijiang"] = "请发动“激将”",
	["~jijiang"] = "选择【杀】的目标角色→点击确定",

	["#diy_gongsunzan"] = "白马将军",
	["diy_gongsunzan"] = "公孙瓒-贴纸",
	["&diy_gongsunzan"] = "公孙瓒",
	["illustrator:diy_gongsunzan"] = "XXX",
	["designer:diy_gongsunzan"] = "爱放泡的鱼",
	["diyyicong"] = "义从",
	[":diyyicong"] = "弃牌阶段结束时，你可以将任意数量的牌置于武将牌上，称为“扈”。其他角色与你的距离+X。（X为“扈”的数量）",
	["tuqi"] = "突骑",
	[":tuqi"] = "<font color=\"blue\"><b>锁定技，</b></font>准备阶段开始时，若你的武将牌上有“扈”，你将所有“扈”置入弃牌堆：若X小于或等于2，你摸一张牌。本回合你与其他角色的距离-X。（X为准备阶段开始时置于弃牌堆的“扈”的数量）",
	["retinue"] = "扈",
	["@diyyicong"] = "你可以发动“义从”",
	["~diyyicong"] = "选择若干张牌→点击确定",
	["#diyyicong-dist"] = "义从",
	["#tuqi-dist"] = "突骑",

	["#diy_xinxianying"] = "明鉴之才" ,
	["diy_xinxianying"] = "辛宪英" ,
	["illustrator:diy_xinxianying"] = "鸿仑" ,
	["designer:diy_xinxianying"] = "KISS_飞雪" ,
	["mingjian"] = "明鉴" ,
	[":mingjian"] = "任意角色的准备阶段开始时，你可以选择一项：弃置一张牌，跳过该角色的判定阶段，或将一张手牌竖置在该角色的武将牌上，则该角色本回合内的判定结果不能被代替或替换，回合结束后，将该牌置入弃牌堆。" ,
	["@mingjian-discard"] = "你可以弃置1张牌，跳过该角色的判定阶段" ,
	["@mingjian-put"] = "你可以将一张牌移出游戏，该角色判定不可更改" ,
	["#preventretrial"] = "受到 %arg 技能影响， %from 的判定牌不可被代替或替换。" ,
	["yinzhi"] = "隐智" ,
	[":yinzhi"] = "你每受到一点伤害，可以展示牌堆顶的两张牌，其中每有一张黑桃牌，你可以令一名角色获得伤害来源的一张牌，然后你将这些黑桃牌置于弃牌堆，并获得其余的牌。" ,
	["@yinzhi-select"] = "你可以选择一名角色获得伤害来源的一张牌。" ,
}
