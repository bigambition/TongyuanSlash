----------------建模组-----------------------
----------同甘-------------
--同甘 ：每当你回复体力时，你可以指定1-2名其他角色各回复一点体力。
sgs.ai_skill_use["@@tonggan"] = function(self, prompt, method)
	self:sort(self.friends,"hp")
	local targets={}
	for _,friend in ipairs(self.friends) do
		if friend:isWounded() and friend:objectName()~=self.player:objectName() then
			table.insert(targets,friend:objectName())
		end
		if #targets==2 then break end
	end
	if #targets==0 then return "." end
	return "@TongganCard=.->"..table.concat(targets, "+")	
end
-----------共苦---------------
--共苦：每当你收到伤害后，你可以指定1-2名角色各失去一点体力
sgs.ai_skill_use["@@gongku"] = function(self, prompt, method)
	self:sort(self.enemies,"hp")
	local targets={}
	for _,enemy in ipairs(self.enemies) do		
		table.insert(targets,enemy:objectName())		
		if #targets==2 then break end
	end
	if #targets==0 then return "." end
	return "@GongkuCard=.->"..table.concat(targets, "+")		
end
------------大腿--------------
--大腿：当有角色进入濒死状态时，你可以进行一次判定，若结果为红色，其回复一点体力
sgs.ai_skill_invoke["datui"] = function(self, data)
	local dying = data:toDying()
	if self.role == "renegade" and not (dying.who:isLord() or dying.who:objectName() == self.player:objectName())
	 and 
			(sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"] or 
				self.room:getCurrent():objectName() == self.player:objectName()) then
		return false
	end
	return self:isFriend(dying.who) or dying.who:objectName() == self.player:objectName()	
end
------------何必---------------
--何必：在一名角色的判定牌生效前，你可以打出一张红色牌替换之。
-- sgs.ai_skill_invoke["hebi"] = function(self, data)
-- 	local judge = data:toJudge()
-- 	local all_cards = self.player:getCards("he")
-- 	if all_cards:isEmpty() then return false end
-- 	local cards = {}
-- 	local heart = {}
-- 	local diamond = {}
-- 	for _, card in sgs.qlist(all_cards) do
-- 		if card:isRed() then
-- 			table.insert(cards, card)
-- 			if card:getSuit() == sgs.Card_Heart then
-- 				table.insert(heart, card)
-- 			else
-- 				table.insert(diamond, card)
-- 			end
-- 		end
-- 	end
-- 	if #cards == 0 then return false end
-- 	self:sortByUseValue(cards)
-- 	local who=judge.who
-- 	local reason = judge.reason
-- 	if reason=="luadatui" or "datui" then
-- 		local dying = data:toDying()
-- 		local whox = dying.who
-- 		if self:isFriend(whox) then
-- 			if not judge:isGood() then
-- 				return true	
-- 			elseif (judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo")) then
-- 				return true
-- 			end 				
-- 		else
-- 			if judge:isGood() then
-- 				if (judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo")) then
-- 					return true
-- 				end
-- 			end			
-- 		end			
-- 	elseif reason=="luoshen" then
-- 		if self:isEnemy(who) then
-- 			if judge:isGood() then
-- 				return true
-- 			elseif judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo") then
-- 				return true
-- 			end
-- 		elseif not judge:isGood() then
-- 			if judge.card:isKindOf("Peach") or judge.card:isKindOf("ExNihilo") then
-- 				return true
-- 			end			
-- 		end		
-- 	elseif reason == "indulgence" then
-- 		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") or 
-- 			judge.card:isKindOf("ExNihilo")) and #heart ~= 0 then
-- 			return true
-- 		elseif self:isEnemy(who) and #diamond ~= 0 then
-- 			return judge:isGood()		
-- 		end
-- 	elseif reason == "ganglie" then
-- 		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") or 
-- 			judge.card:isKindOf("ExNihilo")) then
-- 			return true
-- 		elseif self:isEnemy(who) and #heart ~= 0 then
-- 			return judge:isGood()
-- 		end		
-- 	end 
-- 	if self:isFriend(who) and not judge:isGood() then
-- 	 	return true 
-- 	elseif self:isEnemy(who) then
-- 		return judge:isGood() 
-- 	end
-- 	return false
-- end
sgs.ai_skill_cardask["@hebi-card"]=function(self, data, pattern, target, target2)
	local judge = data:toJudge()
	local all_cards = sgs.QList2Table(self.player:getCards("he"))
	if #all_cards==0 then return "." end
	local cards = {}
	local heart = {}
	local diamond = {}
	for _, card in ipairs(all_cards) do
		if card:isRed() and not card:hasFlag("using") then
			table.insert(cards, card)
			if card:getSuit() == sgs.Card_Heart then
				table.insert(heart, card)
			else
				table.insert(diamond, card)
			end
		end
	end
	if #cards == 0 then return "." end
	self:sortByUseValue(cards)
	local who=judge.who
	local reason = judge.reason
	local card = cards[1]
	--assert(card)
	if reason=="luadatui" or reason=="datui" then
		-- local dying = data:toDying()
		-- local whox = dying.who
		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") or 
			judge.card:isKindOf("ExNihilo"))then
			return "$" .. card:getId()		
		else
			return "."
		end	
	elseif reason=="luoshen" then
		if self:isEnemy(who) and judge:isGood() then
			return "$" .. card:getId()
		elseif self:isFriend(who) and not judge:isGood() and (judge.card:isKindOf("Peach") or 
			judge.card:isKindOf("ExNihilo")) then
			return "$" .. card:getId()
		else
			return "."
		end
	elseif reason == "indulgence" then
		--local card=nil
		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") or 
			judge.card:isKindOf("ExNihilo")) and #heart~= 0 then
			return "$" .. heart[1]:getId()						
		elseif self:isEnemy(who) and judge:isGood() and #diamond ~= 0 then
			return "$" .. diamond[1]:getId()			
		else
			return "."
		end
	elseif reason == "ganglie" then		
		if self:isFriend(who) and (not judge:isGood() or judge.card:isKindOf("Peach") 
			or judge.card:isKindOf("ExNihilo")) and #diamond ~= 0 then
			return "$" .. diamond[1]:getId()			
		elseif self:isEnemy(who) and judge:isGood() and #heart~= 0 then
			return "$" .. heart[1]:getId()			
		else
			return "."
		end
	end
	if self:isFriend(who) and not judge:isGood() and (judge.card:isKindOf("Peach") 
			or judge.card:isKindOf("ExNihilo")) then
	 	return "$" .. card:getId() 
	elseif self:isEnemy(who) and judge:isGood() then
		return "$" .. card:getId()
	end
	return "." or "$" .. card:getId() 
end
-----------自残----------
--自残：每当你将对一名其他角色造成伤害时，你可以自减与该伤害等量的体力，然后你对该角色造成的伤害加倍
sgs.ai_skill_invoke["zican"] = function(self, data)
	local damage = data:toDamage()		
	local victim = damage.to
	local x = damage.damage	
	local hp = self.player:getHp()
	local peach = 0
	local analeptic = 0
	if self:isFriend(victim) then return false end
	if hp < x then return false end	
	if self:isEnemy(victim)  and not victim:hasArmorEffect("SilverLion") then
		if self.role =="rebel" and victim:isLord() and victim:getHp() <=2 and #self.friends>0 then return true end	
		local cards = self.player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:isKindOf("Peach") then
				peach = peach + 1
				analeptic = analeptic + 1
			elseif card:isKindOf("Analeptic")  then
				analeptic = analeptic + 1
			end				
		end		
		if hp == x then
			if analeptic < x-hp+1 then return false end
			return true
		elseif 	2*peach+hp-x-self.player:getHandcardNum()+2>=0 then
			return true
		end
		return false
	end	
end
-----------扶持-----------------
local fuchiv_skill = {}
fuchiv_skill.name = "fuchiv"
table.insert(sgs.ai_skills, fuchiv_skill)
fuchiv_skill.getTurnUseCard = function(self)
	if self.player:hasFlag("ForbidFuchi") then return nil end
	if self.player:getKingdom() ~= "mo" then return nil end			
	local cards = self.player:getCards("he")		
	if cards:length()==0 then return nil end
	return sgs.Card_Parse("@FuchiCard=.")	
end
sgs.ai_skill_use_func.FuchiCard = function(card, use, self)	
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)	
	if #cards==0 then return "." end--若总数为0则不发动
	local ids={}
	for _,card in ipairs(cards) do
		table.insert(ids,card:getId())
	end 
	local lord = self.room:getLord()--若身份为忠臣且主公很虚弱时，发动
	-- if lord:hasFlag("FuchiInvoked") then return end
	if lord:hasLordSkill("fuchi") and not lord:hasFlag("FuchiInvoked") and self.role == "loyalist" then		
		use.card = sgs.Card_Parse("@FuchiCard="..table.concat(ids,"+"))
		if use.to then
			use.to:append(lord)			
		end
	end	
	
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("fuchi") then
			if not friend:hasFlag("FuchiInvoked") then
				if not friend:hasSkill("manjuan") then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --膜拜己方
		use.card = sgs.Card_Parse("@FuchiCard="..table.concat(ids,"+"))
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])			
		end
	elseif self:getCardsNum("Slash", self.player, "he") >= 2 then --黄天对方
		for _,enemy in ipairs(self.enemies) do
			if enemy:hasLordSkill("fuchi") then
				if not enemy:hasFlag("FuchiInvoked") then
					if not enemy:hasSkill("FuchiInvoked") then
						if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and not 
						enemy:hasSkills("tuntian+zaoxian") then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:hasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:hasUsed("XianzhenCard") then
				flag = true
			elseif self.player:hasSkill("luatiaokan") and not self.player:hasUsed("luatiaokanCard") then
				flag = true 
			end
			if flag then
				local maxCard = self:getMaxCard(self.player) --最大点数的手牌
				if maxCard:getNumber() > analeptic[1]:getNumber() then --可以保证拼点成功
					self:sort(targets, "defense")
					targets = sgs.reverse(targets) 
					for _,enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
							use.card = sgs.Card_Parse("@FuchiCard=%d",cards[1]:getId())
							enemy:setFlags("AI_shoujiPindian")
							if use.to then
								use.to:append(enemy)
							end
							break
						end
					end
				end
			end
		end
	end    
end

sgs.ai_card_intention.FuchiCard = -80
sgs.ai_use_priority.FuchiCard = 3
sgs.ai_use_value.FuchiCard = 2.5
--女汉
sgs.ai_skill_invoke["nvhan"] = function(self,data)
	if self.player:containsTrick("indulgence") then return false end
	if self.player:getCards("he"):length()<=3 then return false end
	local slash = 0
	local peach = 0
	for _,card in sgs.qlist(self.player:getCards("he")) do
		if card:isKindOf("Slash") or (card:isRed() and not card:isKindOf("Peach")) then slash = slash+1 end
		if card:isKindOf("Peach") then peach = peach + 1 end
	end	
	local target = 0
	for _,t in ipairs(self.enemies) do
		if self.player:inMyAttackRange(t) then target = 1 break end
	end
	return slash>2 and target>0 and (peach+self.player:getHp()>=2)
end
--圈圈
sgs.ai_skill_use["@@quanquan"] = function(self, prompt, method)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local basic = {}
	for _,card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_Basic then
			table.insert(basic,card:getId())
		end
	end
	if #basic == 0 then return "." end	
	local k = {}
	for _,id in ipairs(basic) do
		table.insert(k,id)
		if #k==3 then break end
	end
	return "@QuanquanCard="..table.concat(k,"+")
end
--小胖
local xiaopang_skill = {}
xiaopang_skill.name = "xiaopang"
table.insert(sgs.ai_skills, xiaopang_skill)
xiaopang_skill.getTurnUseCard = function(self)
	if self.player:getPhase() ~= sgs.Player_NotActive then return "." end
	if self.player:getPile("QQ"):isEmpty() then return "." end
	return sgs.Card_Parse("@XiaopangCard=.")
end
sgs.ai_skill_use_func["XiaopangCard"] = function(card, use, self)
	use.card = card
end
-- sgs.ai_view_as.xiaopang = function(card, player, card_place)
-- 	if player:getPhase() ~= sgs.Player_NotActive then return end
-- 	if player:getPile("QQ"):isEmpty() then return end
-- 	return "@XiaopangCard=."
-- end

sgs.ai_skill_invoke["xiaopang"] = function(self, data)
	local asked = data:toStringList()
	local pattern = asked[1]
	local prompt = asked[2]
	return self:askForCard(pattern, prompt, 1) ~= "."
end

--厚积
sgs.ai_skill_choice["houji"] = function(self, choices, data)
	local hp = self.player:getHp()
	local count = self.player:getHandcardNum()
	if hp >= count + 2 then
		return "draw"
	else
		return "recover"
	end
end
--口味
sgs.ai_skill_cardask["@kouwei-increase"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then return "." end
	if target:hasArmorEffect("SilverLion") then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:isBlack() then return "$" .. card:getEffectiveId() end
	end
	return "."
end

sgs.ai_skill_cardask["@kouwei-decrease"] = function(self, data)
	local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if damage.card and damage.card:isKindOf("Slash") then
		if self:hasHeavySlashDamage(damage.from, damage.card, self.player) then
			for _,card in ipairs(cards) do
				if card:isRed() then return "$" .. card:getEffectiveId() end
			end
		end
	end
	if self:getDamagedEffects(self.player, damage.from) and damage.damage <= 1 then return "." end
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then return "." end
	for _,card in ipairs(cards) do
		if card:isRed() then return "$" .. card:getEffectiveId() end
	end
	return "."
end

sgs.ai_cardneed.kouwei = sgs.ai_cardneed.beige
--大头
sgs.ai_skill_invoke.datou = function(self, data)
    local target = data:toPlayer()
	if self:isFriend(target) then
		self.datou_target = target
        return true
	end
    return false	
end
sgs.ai_skill_discard.datou = function(self)
    local target = self.datou_target
	local best_card, better_card, normal_card
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	for _, cd in sgs.list(self.player:getHandcards()) do
	    if (self:getCardsNum("Jink", target) == 0 and cd:isKindOf("Jink")) or ((not target:getArmor() or 
	    	target:hasArmorEffect("SilverLion")) and cd:isKindOf("Armor")) then
		    best_card = cd
		elseif (not target:getWeapon() and cd:isKindOf("Weapon")) or (not target:getDefensiveHorse() and 
			cd:isKindOf("DefensiveHorse")) or (not target:getOffensiveHorse() and cd:isKindOf("OffensiveHorse")) then
		    better_card = cd
		else
		    normal_card = cd
		end
	end
	local to_give = best_card or better_card or normal_card
	local r = {}
	if to_give then
		table.insert(r, to_give:getEffectiveId())
	else
		table.insert(r, self.player:getRandomHandcardId())
	end
	return r
end
sgs.ai_chaofeng.baobingrui = 3
sgs.ai_cardneed.datou = function(to, card, self)
    if to:getHandcardNum() < 4 then
	    return card:isKindOf("EquipCard") or card:isKindOf("Jink")
	end
end
--仿真
sgs.ai_skill_invoke["fangzhen"] = function(self,data)
	if self.player:getMark("@mo") == 0 then return false end
	local currentplayer = self.room:getCurrent()
	local skill={} 
	for _,ski in sgs.qlist(currentplayer:getVisibleSkillList()) do
		if not ski:isLordSkill() and ski:getFrequency() ~= sgs.Skill_Limited and
		ski:getFrequency() ~= sgs.Skill_Wake then
			table.insert(skill,ski:objectName())
		end
	end
	if #skill == 0 then return false end
	for _,ski in ipairs(skill) do
		for _, askill in ipairs(("xiaozi|datui|gongku|tonggan|shuishen|benxi|mengmei|huijia|suanfa|houji|"..
			"bofa|kouwei|feiyu|biye|yeya|peixun|cheli|wocao|nima|xuebeng|jingxiang|dedao|tuhao|"..
			"yingdi|dese|jicuo|chandao|jiucuo|chihuo|ziyu|laoshi|deyi|chidao|weikou|shualai|"..
			"houge|xinkuan|suihe|jizhi|yushen|jiushen|biaoyan|shoucang|quanjiu|aixiao|chuyi|youyong|"..
			"weihu|jixiao|qiujie|zhidao|cheshi"):split("|")) do
			if ski == askill then return true end
		end	
	end
	return false
end
sgs.ai_skill_choice["fangzhen"] = function(self, choices, data)
	local str = choices
	for _, askill in ipairs(("xiaozi|datui|gongku|tonggan|shuishen|benxi|mengmei|huijia|suanfa|houji|"..
			"bofa|kouwei|feiyu|biye|yeya|peixun|cheli|wocao|nima|xuebeng|jingxiang|dedao|tuhao|"..
			"yingdi|dese|jicuo|jiucuo|chandao|chihuo|ziyu|laoshi|deyi|chidao|weikou|shualai|"..
			"houge|xinkuan|suihe|jizhi|yushen|jiushen|biaoyan|shoucang|quanjiu|aixiao|chuyi|youyong|"..
			"weihu|jixiao|qiujie|zhidao"):split("|")) do
		if str:matchOne(askill) then return askill end
	end	
end
--拥护
sgs.ai_skill_playerchosen.yonghu = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:isAlive() then
			return target
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.yonghu = -50
--弃博
local qibo_skill={}
qibo_skill.name="qibo"
table.insert(sgs.ai_skills,qibo_skill)
qibo_skill.getTurnUseCard=function(self,inclusive)
	--特殊场景
	local func = Tactic("qibo", self, nil)
	if func then return func(self, nil) end
	--一般场景
	local losthp = isLord(self.player) and 0 or 1
	if ((self.player:getHp() > 3 and self.player:getLostHp() <= losthp and 
		self.player:getHandcardNum() > self.player:getHp())
		or (self.player:getHp() - self.player:getHandcardNum() >= 2)) and not (isLord(self.player) and
		 sgs.turncount <= 1) then
		return sgs.Card_Parse("@QiboCard=.")
	end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	if (self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")) or self:hasSkills("paoxiao") then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, nil, true) and self:slashIsEffective(slash, enemy)
			    and not (enemy:hasSkill("kongcheng") and enemy:isKongcheng())
				and not (self:hasSkills("shualai|guixin|shualai", enemy) and not self:hasSkills("paoxiao"))
				and not self:hasSkills("fenyong|jilei|zhichi|chidao", enemy)
				and sgs.isGoodTarget(enemy, self.enemies, self, true) and not self:slashProhibit(slash, enemy) and
				 self.player:getHp()>1 then
				return sgs.Card_Parse("@QiboCard=.")
			end
		end
	end
	if self.player:getHp()==1 and self:getCardsNum("Analeptic")>=1 then
		return sgs.Card_Parse("@QiboCard=.")
	end

	--Suicide by qibo
	local nextplayer = self.player:getNextAlive()
	if self.player:getHp() == 1 and self.player:getRole()~="lord" and self.player:getRole()~="renegade" then
		local to_death = false
		if self:isFriend(nextplayer) then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasSkills("gzcheli|cheli|cheli") and not self:isFriend(p) and not p:isKongcheng()
					and self.role == "rebel" and self.player:getEquips():isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkill("jieyin") and self.player:isMale() then return end
				if nextplayer:hasSkill("chuyi") then return end
			end
		end
		if self.player:getRole()=="rebel" and not self:isFriend(nextplayer) then
			if not self:willSkipPlayPhase(nextplayer) or nextplayer:hasSkill("shensu") then
				to_death = true
			end
		end
		local lord = getLord(self.player)
		if self.player:getRole()=="loyalist" then
			if lord and lord:getCards("he"):isEmpty() then return end
			if self:isEnemy(nextplayer) and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkills("noslijian|lijian") and self.player:isMale() and lord and lord:isMale() then
					to_death = true
				elseif nextplayer:hasSkill("quhu") and lord and lord:getHp() > nextplayer:getHp() and
				 not lord:isKongcheng()
					and lord:inMyAttackRange(self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = self.room:findPlayerBySkillName("xingshang")
			if caopi and self:isEnemy(caopi) then
				if self.player:getRole() == "rebel" and self.player:getHandcardNum() > 3 then to_death = false end
				if self.player:getRole() == "loyalist" and lord and 
					lord:getCardCount(true) + 2 <= self.player:getHandcardNum() then
					to_death = false
				end
			end
			if #self.friends == 1 and #self.enemies == 1 and self.player:aliveCount() == 2 then to_death = false end
		end
		if to_death then
			self.player:setFlags("qibo_toDie")
			return sgs.Card_Parse("@QiboCard=.")
		end
		self.player:setFlags("-qibo_toDie")
	end
end

sgs.ai_skill_use_func["QiboCard"]=function(card,use,self)
	use.card=card
end

sgs.ai_use_priority.QiboCard = 6.8

sgs.ai_chaofeng.xuxuehai = 3
--液压
local yeya_skill={}
yeya_skill.name="yeya"
table.insert(sgs.ai_skills,yeya_skill)
yeya_skill.getTurnUseCard=function(self)
	if not sgs.Analeptic_IsAvailable(self.player, analeptic) and not self:slashIsAvailable() 
		or self.player:isKongcheng() then return nil end
	local slash,analeptic = nil,nil
	local cards1 = self.player:getHandcards()
	local cards = sgs.QList2Table(cards1)
	self:sortByUseValue(cards)
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") then
			slash = card
			break			
		end		
	end
	for _,card in ipairs(cards) do		
		if card:isKindOf("Analeptic") then
			analeptic = card
			break			
		end
	end
	if slash then
		local suit = slash:getSuitString()
		local point = slash:getNumberString()
		local id = slash:getId()
		local str = string.format("analeptic:yeya[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(str)
	end	
	if analeptic then
		local suit = analeptic:getSuitString()
		local point = analeptic:getNumberString()
		local id = analeptic:getId()
		local str = string.format("slash:yeya[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(str)
	end			
end
sgs.ai_view_as.yeya = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceEquip then
		if card:isKindOf("Slash") then
			return string.format("analeptic:yeya[%s:%s]=%d", suit, number, card_id)
		elseif card:isKindOf("Analeptic") then
			return string.format("slash:yeya[%s:%s]=%d", suit, number, card_id)
		end
	end
end
--培训
sgs.ai_skill_invoke["peixun"]= function(self,data)
	if self.player:isKongcheng() or not self.player:canDiscard(self.player,"h")	then return false end
	local bad = false
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") then
			bad = true
			break
		end
	end 
	if bad == false then return false end
	local currentplayer = self.room:getCurrent()
	if self:isFriend(currentplayer) then
		if currentplayer:getCardCount(true) > currentplayer:getHp()+2 then return true end
	else
		if not currentplayer:isWounded() or currentplayer:getCardCount(true) <2 then return true end
	end
	return false
end

sgs.ai_skill_choice["peixun"] = function(self, choices, data)
	local hp = self.player:getHp()
	local count = self.player:getCardCount(true)
	if hp >= count + 2 then
		return "damage"
	else
		return "discard1"
	end
end
--援助
local function yuanzhu_validate(self, equip_type, is_handcard)
	local is_SilverLion = false
	if equip_type == "SilverLion" then
		equip_type = "Armor"
		is_SilverLion = true
	end
	local targets
	if is_handcard then targets = self.friends else targets = self.friends_noself end
	if equip_type ~= "Weapon" then
		if equip_type == "DefensiveHorse" or equip_type == "OffensiveHorse" then self:sort(targets, "hp") end
		if equip_type == "Armor" then self:sort(targets, "handcard") end
		if is_SilverLion then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
					local seat_diff = enemy:getSeat() - self.player:getSeat()
					local alive_count = self.room:alivePlayerCount()
					if seat_diff < 0 then seat_diff = seat_diff + alive_count end
					if seat_diff > alive_count / 2.5 + 1 then return enemy	end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if self:hasSkills("bazhen|yizhong", enemy) then
					return enemy
				end
			end
		end
		for _, friend in ipairs(targets) do
			local has_equip = false
			for _, equip in sgs.qlist(friend:getEquips()) do
				if equip:isKindOf(equip_type) then
					has_equip = true
					break
				end
			end
			if not has_equip then
				if equip_type == "Armor" then
					if not self:needKongcheng(friend, true) and not self:hasSkills("bazhen|yizhong", friend) then
					 return friend end
				else
					if friend:isWounded() and not (friend:hasSkill("longhun") and friend:getCardCount(true) >= 3) 
					then return friend end
				end
			end
		end
	else
		for _, friend in ipairs(targets) do
			local has_equip = false
			for _, equip in sgs.qlist(friend:getEquips()) do
				if equip:isKindOf(equip_type) then
					has_equip = true
					break
				end
			end
			if not has_equip then
				for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
					if friend:distanceTo(aplayer) == 1 then
						if self:isFriend(aplayer) and not aplayer:containsTrick("YanxiaoCard")
							and (aplayer:containsTrick("indulgence") or aplayer:containsTrick("supply_shortage")
								or (aplayer:containsTrick("lightning") and self:hasWizard(self.enemies))) then
							aplayer:setFlags("AI_yuanzhuToChoose")
							return friend
						end
					end
				end
				self:sort(self.enemies, "defense")
				for _, enemy in ipairs(self.enemies) do
					if friend:distanceTo(enemy) == 1 and self.player:canDiscard(enemy, "he") then
						enemy:setFlags("AI_yuanzhuToChoose")
						return friend
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use["@@yuanzhu"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:hasArmorEffect("SilverLion") then
		local player = yuanzhu_validate(self, "SilverLion", false)
		if player then return "@YuanzhuCard=" .. self.player:getArmor():getEffectiveId() .. "->" .. player:objectName() end
	end
	if self.player:getOffensiveHorse() then
		local player = yuanzhu_validate(self, "OffensiveHorse", false)
		if player then return "@YuanzhuCard=" .. self.player:getOffensiveHorse():getEffectiveId() .. "->" .. player:objectName() end
	end
	if self.player:getWeapon() then
		local player = yuanzhu_validate(self, "Weapon", false)
		if player then return "@YuanzhuCard=" .. self.player:getWeapon():getEffectiveId() .. "->" .. player:objectName() end
	end
	if self.player:getArmor() and self.player:getLostHp() <= 1 and self.player:getHandcardNum() >= 3 then
		local player = yuanzhu_validate(self, "Armor", false)
		if player then return "@YuanzhuCard=" .. self.player:getArmor():getEffectiveId() .. "->" .. player:objectName() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("DefensiveHorse") then
			local player = yuanzhu_validate(self, "DefensiveHorse", true)
			if player then return "@YuanzhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("OffensiveHorse") then
			local player = yuanzhu_validate(self, "OffensiveHorse", true)
			if player then return "@YuanzhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			local player = yuanzhu_validate(self, "Weapon", true)
			if player then return "@YuanzhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("SilverLion") then
			local player = yuanzhu_validate(self, "SilverLion", true)
			if player then return "@YuanzhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
		if card:isKindOf("Armor") and yuanzhu_validate(self, "Armor", true) then
			local player = yuanzhu_validate(self, "Armor", true)
			if player then return "@YuanzhuCard=" .. card:getEffectiveId() .. "->" .. player:objectName() end
		end
	end
end

sgs.ai_skill_playerchosen.yuanzhu = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if p:hasFlag("AI_yuanzhuToChoose") then
			p:setFlags("-AI_yuanzhuToChoose")
			return p
		end
	end
	return targets[1]
end

sgs.ai_card_intention.YuanzhuCard = function(self, card, from, to)
	if to[1]:hasSkill("bazhen") or to[1]:hasSkill("yizhong") or (to[1]:hasSkill("kongcheng") and 
		to[1]:isKongcheng()) then
		if sgs.Sanguosha:getCard(card:getEffectiveId()):isKindOf("SilverLion") then
			sgs.updateIntention(from, to[1], 10)
			return
		end
	end
	sgs.updateIntention(from, to[1], -50)
end

sgs.ai_cardneed.yuanzhu = sgs.ai_cardneed.equip

sgs.yuanzhu_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 4.7,
	Armor = 4.8,
	Horse = 4.9
}

--撤离
sgs.ai_skill_cardask["@cheli"] = function(self, data)
	local currentplayer = self.room:getCurrent()

	local has_anal, has_slash, has_jink
	for _, acard in sgs.qlist(self.player:getHandcards()) do
		if acard:isKindOf("Analeptic") then has_anal = acard
		elseif acard:isKindOf("Slash") then has_slash = acard
		elseif acard:isKindOf("Jink") then has_jink = acard
		end
	end

	local card

	if has_slash then card = has_slash
	elseif has_jink then card = has_jink
	elseif has_anal then
		if not self:isWeak() or self:getCardsNum("Analeptic") > 1 then
			card = has_anal
		end
	end

	if not card then return "." end
	if self:isFriend(currentplayer) then
		if self:needToThrowArmor(currentplayer) then
			if card:isKindOf("Slash") or (card:isKindOf("Jink") and self:getCardsNum("Jink") > 1) then
				return "$" .. card:getEffectiveId()
			else return "."
			end
		end
	elseif self:isEnemy(currentplayer) then
		if not self:damageIsEffective(currentplayer, sgs.DamageStruct_Normal, self.player) then return "." end
		if self:getDamagedEffects(currentplayer, self.player) or self:needToLoseHp(currentplayer, self.player) then
			return "."
		end
		if self:needToThrowArmor(currentplayer) then return "." end
		if self:hasSkills(sgs.lose_equip_skill, currentplayer) and currentplayer:getCards("e"):length() > 0 then 
			return "." end
		return "$" .. card:getEffectiveId()
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@cheli"] = function(player, promptlist, self)
	if promptlist[#promptlist] ~= "_nil_" then
		local current = player:getRoom():getCurrent()
		if not current then return end
		local intention = 10
		if self:hasSkills(sgs.lose_equip_skill, current) and current:getCards("e"):length() > 0 then intention = 0 end
		if self:needToThrowArmor(current) then intention = 0 end
		sgs.updateIntention(player, current, intention)
	end
end

sgs.ai_skill_cardask["@cheli-discard"] = function(self, data)
	local yuejin = self.room:findPlayerBySkillName("cheli")
	local player = self.player

	if self:needToThrowArmor() then
		return "$" .. player:getArmor():getEffectiveId()
	end

	if not self:damageIsEffective(player, sgs.DamageStruct_Normal, yuejin) then
		return "."
	end
	if self:getDamagedEffects(self.player, yuejin) then
		return "."
	end
	if self:needToLoseHp(player, yuejin) then
		return "."
	end

	local card_id
	if self:hasSkills(sgs.lose_equip_skill, player) then
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getArmor() then card_id = player:getArmor():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		end
	end

	if not card_id then
		for _, card in sgs.qlist(player:getCards("h")) do
			if card:isKindOf("EquipCard") then
				card_id = card:getEffectiveId()
				break
			end
		end
	end

	if not card_id then
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif self:isWeak(player) and player:getArmor() then card_id = player:getArmor():getId()
		elseif self:isWeak(player) and player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		end
	end

	if not card_id then
		return "."
	else
		return "$" .. card_id
	end
	return "."
end

sgs.ai_cardneed.cheli = function(to, card)
	return getKnownCard(to, "BasicCard", true) == 0 and card:getTypeId() == sgs.Card_Basic
end

sgs.ai_chaofeng.heshan = 2
--卧槽
sgs.ai_skill_invoke["wocao"] = function(self,data)
	if self.player:isKongcheng() or not self.player:canDiscard(self.player,"h")	then return false end
	local bad = false
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") then
			bad = true
			break
		end
	end 
	if bad == false then return false end
	local use = data:toCardUse()
	return self:isEnemy(use.from)
end
--尼玛
sgs.ai_skill_invoke["nima"] = function(self,data)
	if self.player:isKongcheng() or not self.player:canDiscard(self.player,"h")	then return false end
	local bad = false
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") then
			bad = true
			break
		end
	end 
	if bad == false then return false end
	local use = data:toSlashEffect()
	return self:isEnemy(use.to)
end
-----------------------------------------------------------------
----------------------武汉研发部、嵌入式组---------------------
--睡神
sgs.ai_skill_choice["shuishen"] = function(self, choices, data)
	if self.player:isWounded() then
		local cards=self.player:getCards("j")
		for _,card in sgs.qlist(cards) do 
			if card:isKindOf("indulgence") then
				return "recover"				
			end
		end
		local hp = self.player:getHp()
		local count = self.player:getHandcardNum()
		if hp >= count + 2 then
			return "draw"
		else
			return "recover"
		end
	end
	return "draw"
end
--时尚
sgs.ai_skill_invoke["shishang"] = function(self, data)
	local damage = data:toDamage()		
	local victim = damage.to
	local peach = 0
	if self:isEnemy(victim) then return false end
	if self.player:getHp() <=0 then return false end
	if self:isFriend(victim) and self:isWeak(victim) then 
		if self.player:getHp() == 1 then
			if self.role == "loyalist" and victim:isLord() and victim:getHp()<=2 then return true end
			local cards = self.player:getHandcards()
			for _,card in sgs.qlist(cards) do
				if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
					peach = peach + 1
				end				
			end
			if peach == 0 then return false end
			return true
		end	
		return true
	end
	if self.player:getLostHp() + self.player:getHandcardNum() >4 then return false end
	return false
end
--侯哥
local houge_skill={}
houge_skill.name="houge"
table.insert(sgs.ai_skills,houge_skill)
houge_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)	
	if #cards == 0 then return nil end
	for _, card in ipairs(cards) do
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()		
		if card:isKindOf("EquipCard") then
			return sgs.Card_Parse(string.format("savage_assault:houge[%s:%s]=%d", suit, point, id))			
		end		 			
	end
end
--心宽
sgs.ai_skill_invoke["xinkuan"] = function(self,data)	
	local damage = data:toDamage()
	local from = damage.from
	if from:objectName()~=self.player:objectName() then return false end	
	local target = damage.to
	if damage.card:hasFlag("drank") then return false end
	if self.player:getHp()+2<=self.player:getHandcardNum()
		and self.player:getPhase() ~= sgs.Player_NotActive then return true end
	if self:isFriend(target) then
		if self:isWeak(target) or damage.damage > 1 then return true
		elseif target:getLostHp() < 1 then return false end
		return true
	else
		if self:isWeak(target) then return false end
		if damage.damage > 1 or self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and
		 not (target:hasArmorEffect("SilverLion") and target:isWounded()) then return true end
		local num = target:getHandcardNum()
		if self.player:hasSkill("leili") or self:canLiegong(target, self.player) then return false end
		if target:hasSkills("tuntian+zaoxian") then return false end
		if self:hasSkills(sgs.need_kongcheng, target) then return false end
		if target:getCards("he"):length()<4 and target:getCards("he"):length()>1 then return true end
		return false
	end
end
sgs.ai_skill_choice["xinkuan"] = function(self, choices, data)
	if self:needBear() or self.player:getHp()+2<=self.player:getHandcards() 
		and self.player:getPhase() ~= sgs.Player_NotActive then return "recover" end
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then return "recover" end
	return "qipai"
end
--随和
sgs.ai_skill_invoke.suihe = function(self, data)
	local target = data:toDamage().from

	if self:isFriend(target) then
		if self:getOverflow(target) > 2 then return true end
		if self:doNotDiscard(target) then return true end
		return (self:hasSkills(sgs.lose_equip_skill, target) and not target:getEquips():isEmpty())
		  or (self:needToThrowArmor(target) and target:getArmor()) or self:doNotDiscard(target)
	end
	if self:isEnemy(target) then		
		return true
	end
	--self:updateLoyalty(-0.8*sgs.ai_loyalty[target:objectName()],self.player:objectName())
	return true
end

sgs.ai_choicemade_filter.cardChosen.suihe = function(player, promptlist, self)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from then
		local intention = 10
		local id = promptlist[3]
		local card = sgs.Sanguosha:getCard(id)
		local target = damage.from
		if self:needToThrowArmor(target) and self.room:getCardPlace(id) == sgs.Player_PlaceEquip and 
			card:isKindOf("Armor") then
			intention = -intention
		elseif self:doNotDiscard(target) then intention = -intention
		elseif self:hasSkills(sgs.lose_equip_skill, target) and not target:getEquips():isEmpty() and
			self.room:getCardPlace(id) == sgs.Player_PlaceEquip and card:isKindOf("EquipCard") then
				intention = -intention		
		elseif self:getOverflow(target) > 2 then intention = 0
		end
		sgs.updateIntention(player, target, intention)
	end
end

sgs.ai_skill_cardchosen.suihe = function(self, who, flags)
	local cards = sgs.QList2Table(who:getEquips())
	local handcards = sgs.QList2Table(who:getHandcards())
	if #handcards==1 and handcards[1]:hasFlag("visible") then table.insert(cards,handcards[1]) end

	for i=1,#cards,1 do
		if (cards[i]:getSuit() == suit and suit ~= sgs.Card_Spade) or
			(cards[i]:getSuit() == suit and suit == sgs.Card_Spade and cards[i]:getNumber() >= 2 and 
				cards[i]:getNumber()<=9) then
			return cards[i]
		end
	end
	return nil
end
--机智
local jizhi_fang_skill={}
jizhi_fang_skill.name="jizhi_fang"
table.insert(sgs.ai_skills,jizhi_fang_skill)
jizhi_fang_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)	
	if #cards == 0 then return nil end
	for _, card in ipairs(cards) do
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()		
		if card:getSuit() == sgs.Card_Club then
			return sgs.Card_Parse(string.format("snatch:jizhi_fang[%s:%s]=%d", suit, point, id))			
		end		 			
	end
end
--大神
local dashen_skill={}
dashen_skill.name="dashen"
table.insert(sgs.ai_skills,dashen_skill)
dashen_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("DashenCard") or self.player:isKongcheng() then return nil end
	local allhandcards = sgs.QList2Table(self.player:getHandcards())
	local ids = {}
	for _,card in ipairs(allhandcards) do 
		table.insert(ids,card:getEffectiveId())
	end
	return sgs.Card_Parse("@DashenCard="..table.concat(ids,"+"))
end
local huixue = false
sgs.ai_skill_use_func.DashenCard = function(card, use, self)
	-- local room = self.player:getRoom
	-- local wounded_frends,wounded_enemies = 0,0
	-- for _,friend in ipairs(self.friends_noself) do
	-- 	if friend:isWounded() then
	-- 		wounded_frends = wounded_frends + 1
	-- 	end
	-- end
	-- for _,enemy in ipairs(self.enemies) do 
	-- 	if enemy:isWounded() then
	-- 		wounded_enemies = wounded_enemies + 1
	-- 	end
	-- end
	if self:willUseGodSalvation(card) then
		huixue = true
		use.card = card
		return
	end
	local friends_ZDL, enemies_ZDL = 0, 0
	local good = (#self.enemies - #self.friends_noself) * 1.5

	if self:isEnemy(self.player:getNextAlive()) and self.player:getHp() > 2 then good = good - 0.5 end
	if self.player:getRole() == "rebel" then good = good + 1 end
	if self.player:getRole() == "renegade" then good = good + 0.5 end
	if not self.player:faceUp() then good = good + 1 end	
	
	if self.role == "renegade" then
		local lord = getLord(self.player)
		if lord and not self:isFriend(lord) and lord:getHp() == 1 and self:damageIsEffective(lord) and 
		self:getCardsNum("Peach") == 0 then return end
	end

	for _, friend in ipairs(self.friends_noself) do
		friends_ZDL = friends_ZDL + friend:getCardCount(true) + friend:getHp()
		if friend:getHandcardNum() > 4 then good = good + friend:getHandcardNum() * 0.25 end
		good = good + self:cansaveplayer(friend)		
		if self:damageIsEffective(friend) then
			if friend:getHp() == 1 and self:getAllPeachNum() < 1 then
				if isLord(friend) then
					good = good - 100				
				end
			else
				good = good - 1
			end
			if isLord(friend) then
				good = good - 0.5
			end
		elseif not self:damageIsEffective(friend) then
			good = good + 1
		end		
	end

	for _,enemy in ipairs(self.enemies) do
		enemies_ZDL = enemies_ZDL + enemy:getCardCount(true) + enemy:getHp()
		if enemy:getHandcardNum() > 4 then good = good - enemy:getHandcardNum()*0.25 end
		good = good - self:cansaveplayer(enemy)

		if self:damageIsEffective(enemy) then
			if isLord(enemy) and self.player:getRole() == "rebel" then
				good = good + 1
			end
			if enemy:getHp() == 1 then
				if isLord(enemy) and self.player:getRole() == "rebel" then
					good = good + 3
				elseif enemy:getRole() ~= "lord" then
					good = good + 1
				end
			end			
		else
			good = good - 1
		end
	end

	local Combat_Effectiveness = ((#self.friends_noself > 0 and 
		friends_ZDL/#self.friends_noself or 0) - (#self.enemies > 0 and enemies_ZDL/#self.enemies or 0))/2
	-- self.room:writeToConsole("friendsZDL:"..friends_ZDL..", enemiesZDL:"..enemies_ZDL..", CE:"..Combat_Effectiveness)
	good = good - Combat_Effectiveness

	-- self.room:writeToConsole("UseShenfen:"..good)
	if good > 0 then
		use.card = card
	end
end
sgs.ai_skill_choice["dashen"] = function(self, choices, data)
	if huixue == true then
		return "recover"
	else
		return "damageto"
	end
end
sgs.ai_use_value.DashenCard = 2
sgs.ai_use_priority.DashenCard = 0.5

--小资
local xiaozi_skill = {}
xiaozi_skill.name = "xiaozi"
table.insert(sgs.ai_skills, xiaozi_skill)
xiaozi_skill.getTurnUseCard = function(self, inclusive)
	local red = nil
	local cards1 = self.player:getCards("he")
	local cards = sgs.QList2Table(cards1)
	self:sortByUseValue(cards)
	for _,card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("ExNihilo") then
			red = card
			break
		end
	end
	if red then
		local suit = red:getSuitString()
		local point = red:getNumberString()
		local id = red:getId()
		local str = string.format("peach:xiaozi[%s:%s]=%d", suit, point, id)
		return sgs.Card_Parse(str)
	end
end
sgs.ai_view_as.xiaozi = function(card, player, card_place, class_name)
	if card:isRed() then
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()
		return string.format("peach:xiaozi[%s:%s]=%d", suit, point, id)
	end
end
sgs.xiaozi_suit_value = {
	heart = 6,
	diamond = 6,
}
--从文
sgs.ai_skill_invoke["congwen"] = function(self,data)
	if self.player:containsTrick("indulgence") then return true end
	local red=0
	for _,card in sgs.qlist(self.player:getHandcards()) do 
		if card:isRed() then red = red + 1 end
	end
	--if self:isWeak(self.player) and red >=1 then return false end
	return red<=2
end
--酒神
jiushen_skill={}
jiushen_skill.name="jiushen"
table.insert(sgs.ai_skills,jiushen_skill)
jiushen_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if acard:isBlack() then
			card = acard
			break
		end
	end

	if not card then return nil end
	local  suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("analeptic:jiushen[%s:%s]=%d"):format(suit,number, card_id)
	local analeptic = sgs.Card_Parse(card_str)

	if sgs.Analeptic_IsAvailable(self.player, analeptic) then
		assert(analeptic)
		return analeptic
	end
end

sgs.ai_view_as.jiushen = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand then
		if card:isBlack() then
			return ("analeptic:jiushen[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

function sgs.ai_cardneed.jiushen(to, card, self)
	return card:isBlack() 
end
--表演
local biaoyan_skill = {}
biaoyan_skill.name = "biaoyan"
table.insert(sgs.ai_skills, biaoyan_skill)
biaoyan_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isWounded() then return nil end
	if self.player:getHandcardNum()<3 then return nil end	
	if self.player:hasUsed("BiaoyanCard") then return nil end
	local peach = 0	
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") then	peach =peach+1 end
	end
	if peach >= self.player:getLostHp() then return nil	end--桃的数量大于等于已损失的体力值就不发动
	if self.player:getLostHp() == 1 and self.player:getHandcardNum() >=5 then return nil end
	--只损失一点体力并且手牌数大于4时不发动。
	return sgs.Card_Parse("@BiaoyanCard=.")
end
sgs.ai_skill_use_func.BiaoyanCard = function(card, use, self)	
	use.card=card
end	
sgs.ai_use_value.BiaoyanCard = 8
sgs.ai_use_priority.BiaoyanCard = 8
--谦虚
local qianxu_skill = {}
qianxu_skill.name = "qianxu"
table.insert(sgs.ai_skills, qianxu_skill)
qianxu_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("QianxuCard") then
		return sgs.Card_Parse("@QianxuCard=.")
	end
end

sgs.ai_skill_use_func.QianxuCard = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp() < 3 then
		local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_anal, keep_weapon = false, false, false, false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
					self:useBasicCard(zcard, dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = { isDummy = true }
					self:useTrickCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(card) then
					local dummy_use = { isDummy = true }
					self:useEquipCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then 
						shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then
				 shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() 
					then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_anal then
					keep_anal = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card)
				 then
					local dummy_use = { isDummy = true }
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then 
			table.insert(use_cards, unpreferedCards[index]) end
	end

	if #use_cards > 0 then
		use.card = sgs.Card_Parse("@QianxuCard=" .. table.concat(use_cards, "+"))
		return
	end
end

sgs.ai_use_value.QianxuCard = 9
sgs.ai_use_priority.QianxuCard = 2.61
sgs.dynamic_value.benefit.QianxuCard = true
sgs.ai_chaofeng.yaoyunzhi = 2

function sgs.ai_cardneed.qianxu(to, card)
	return not card:isKindOf("Jink")
end
--收藏
sgs.ai_skill_invoke.shoucang = function(self)
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.shoucang = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end
--劝酒
sgs.ai_skill_invoke["quanjiu"] = function(self)
	local currentplayer = self.room:getCurrent()
	if self:isFriend(currentplayer) then
		if currentplayer:getHandcardNum() >=3 then return true end
	else
		if currentplayer:getHandcardNum() <=2 then return true end
	end
	return false
end
--宣讲
local function will_invoke_xuanjiang(self)
	local shu,enemynum = 0, 0
	local first = self.player:hasFlag("Global_FirstRound")
	local players = self.room:getOtherPlayers(self.player)
	local shenguanyu = self.room:findPlayerBySkillName("wuhun");
	if shenguanyu ~= nil then
		if shenguanyu:getKingdom() == "yan" then return true end
	end
	for _, player in sgs.qlist(players) do
		if player:getKingdom() == "yan" then
			shu = shu + 1
			if self:isEnemy(player) then
				enemynum = enemynum + 1
			end
		end
	end

	if self.role=="rebel" and self.room:getLord():getKingdom()=="yan" then
		return true
	end

	if shu ==0 then return false end
	if enemynum >0 or shu == 1 then return true end

	if first and shu > 1 and not self:isWeak() then return false end
	return self:isWeak() and shu >0
end

local function player_chosen_xuanjiang(self, targets)
	if not self.room:getLord() then return false end

	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	targets = sgs.reverse(targets)

	if self.role=="rebel" and self.room:getLord():getKingdom()=="yan" then
		return self.room:getLord()
	end

	for _, target in ipairs(targets) do
		if target:hasSkill("wuhun") then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) then
			return target
		end
	end

	for _, target in ipairs(targets) do
		if target:hasSkills("zaiqi|nosenyuan|kuanggu|kofkuanggu|enyuan|shushen") and target:getHp() >= 2 then
			return target
		end
	end
	return targets[1]
end

sgs.ai_skill_use["@@xuanjiang"] = function(self, prompt)
	if will_invoke_xuanjiang(self) then
		local to_discard = self:askForDiscard("xuanjiang", 2, 2, false, true)
		if #to_discard == 2 then
			local shu_generals = sgs.SPlayerList()
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:getKingdom() == "yan" then shu_generals:append(p) end
			end
			if shu_generals:length() == 0 then return "." end
			local target = player_chosen_xuanjiang(self, shu_generals)
			if target then
				return ("@XuanjiangCard=%d+%d->%s"):format(to_discard[1], to_discard[2], target:objectName())
			end
		end
	end
	return "."
end

sgs.ai_need_damaged.xuanjiang = function(self, attacker, player)
	if player:hasLordSkill("xuanjiang") then
		local victim
		for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
			if p:getMark("xuan_" .. player:objectName()) > 0 and p:getMark("@xuan_to") > 0 then
				victim = p
				break
			end
		end
		if victim ~= nil then
			local role
			if sgs.isRolePredictable() and sgs.evaluatePlayerRole(player) == "rebel" or 
				sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				role = "rebel"
			end
			local need_damage = false
			if (sgs.evaluatePlayerRole(player) == "loyalist" or player:isLord()) and role == "rebel" then
			 need_damage = true end
			if sgs.evaluatePlayerRole(player) == "rebel" and role ~= "rebel" then need_damage = true end
			if sgs.evaluatePlayerRole(player) == "renegade" then need_damage = true end
			if victim:isAlive() and need_damage then
				return victim:hasSkill("wuhun") and 2 or 1
			end
		end
	end
	return false
end

sgs.ai_card_intention.xuanjiangCard = function(self, card, from, tos)
	if from:hasSkills("weidi|laoban") and tos[1]:isLord() then
		sgs.updateIntention(from, tos[1], 80)
	end
end
--厨艺
local chuyi_skill = {}
chuyi_skill.name = "chuyi"
table.insert(sgs.ai_skills, chuyi_skill)
chuyi_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return nil end
	if self.player:usedTimes("ChuyiCard") > 0 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a, b)
		local v1 = self:getKeepValue(a) + ( a:isRed() and 50 or 0 ) + ( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b) + ( b:isRed() and 50 or 0 ) + ( b:isKindOf("Peach") and 50 or 0 )
		return v1 < v2
	end
	table.sort(cards, compare_func)

	local card_str = ("@ChuyiCard=%d"):format(cards[1]:getId())
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func.ChuyiCard = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend()
	local target = nil
	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and 
		not self:needToLoseHp(arr1[1], nil, nil, nil, true) then target = arr1[1] end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority.ChuyiCard = 4.2
sgs.ai_card_intention.ChuyiCard = -100

sgs.dynamic_value.benefit.ChuyiCard = true
--游戏
function slashdamage(self,gong,shou)  --定义了一个函数，可以计算，一张杀在不被手牌中的闪闪避时，可以造成的伤害
	local pre = 1	 --默认可造成一点伤害
	local amr=shou:getArmor()
	--以下是判断队友是否有技能鬼才鬼道极略
	local zj = self.room:findPlayerBySkillName("guidao")
	local sm = self.room:findPlayerBySkillName("guicai")
	local ssm = self.room:findPlayerBySkillName("jilve")
	local godlikefriend = false
	if (zj and self:isFriend(zj) and self:canRetrial(zj)) or
		(sm and self:isFriend(sm) and sm:getHandcardNum() >= 2) or
		(ssm and self:isFriend(ssm) and ssm:getHandcardNum() >= 2 and ssm:getMark("@bear") >0 ) then
		godlikefriend = true
	end
	
	--以下完成了这样的计算：
	--如果被杀的人有八卦，藤甲，那么伤害为0
	--如果我有青钢，朱雀，古锭刀并且满足触发条件，那么重新调整伤害值为1或2
	if ame then
		if amr:objectName()=="EightDiagram" or shou:hasSkill("bazhen") or amr:isKindOf("Vine") then
			pre = 0
		end
		if (amr:objectName()=="EightDiagram" or shou:hasSkill("bazhen")) and 
			(gong:hasWeapon("QinggangSword") or godlikefriend == true) then
			pre = 1
		end
		if amr:isKindOf("Vine") and gong:hasWeapon("Fan") then
			pre = 2
		end
		if amr:isKindOf("Vine") and gong:hasWeapon("QinggangSword") then
			pre = 1
		end
		if not amr:objectName()=="SilverLion" and gong:hasWeapon("GudingBlade") and shou:isKongcheng() then
			pre = 2
		end
	else
		if gong:hasWeapon("GudingBlade") and shou:isKongcheng() then
			pre = 2
		end
	end
	--以下目的是：如果被杀的角色拥有技能流离、雷击、刚烈、武魂、挥泪等等技能时，重新调整伤害值为0
	--可以避免对上述技能拥有者出杀
	if self:slashProhibit(nil, shou) then
		pre = 0
	end
	--最后这一段，如果大猪哥空城了，那么重新调整伤害为-100
	--之所以没有调成0，是和后面的代码有关，如果此处调整为0，那么面对0血0牌的诸葛周泰双将，可能Ai会违反空城的规则
	if shou:hasSkill("kongcheng") and shou:isKongcheng() then
		pre = -100
	end
	return pre
end
	
--一下为询问是否发动急速是Ai的处理
sgs.ai_skill_invoke.youxi = function(self, data)
	local besttarget --先整了两个空角色，最佳触发角色和触发角色
	local target
	self:sort(self.enemies,"hp") --这里讲敌人按照体力值排序，也可按防御值排序，我也不知道那个更合理些
	--以下，寻找最佳被杀的人选，如果我此技能一发动，你很有可能就濒死求桃了，那么就选你了
	for _,enemy in ipairs(self.enemies) do
		if sgs.getDefense(enemy) < 6 and slashdamage(self,self.player,enemy) >= enemy:getHp() then
			besttarget = enemy
			break
		end
	end
	--以下，寻找一个可以的人选
	for _,enemy in ipairs(self.enemies) do
		if sgs.getDefense(enemy) < 8 and slashdamage(self,self.player,enemy) > 0 then
			target = enemy
			break
		end
	end
	--以下，确定了要发动技能，标记了杀谁
	--如果你是最佳触发角色，那我是一定会发动的
	--如果你不是最佳触发者，那么还要考虑我自身的状态，这里没有考虑判定区和攻击范围内没人而打酱油的情况，这是因为我不知该如何考虑
	if besttarget then
		self.room:setPlayerFlag(besttarget, "jisu_target")
		return true
	elseif target and sgs.getDefense(self.player) > 8 then
		self.room:setPlayerFlag(target, "jisu_target")
		return true
	else
		return false
	end
	return false
end

--以下是询问 请选择急速的目标 时，AI的选择
--先找到上面已经打上标记的玩家，然后选他就是了
sgs.ai_skill_playerchosen.youxi = function(self, targets)
	local target
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if player:hasFlag("jisu_target") then
			target = player
			self.room:setPlayerFlag(target, "-jisu_target")
		end
	end
	return target
end


-----------------------------------------------------
-----------------------平台组------------------------
--土豪
local tuhao_skill = {}
tuhao_skill.name = "tuhao"
table.insert(sgs.ai_skills, tuhao_skill)
tuhao_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("TuhaoCard") then
		return sgs.Card_Parse("@TuhaoCard=.")
	end
end

sgs.ai_skill_use_func.TuhaoCard = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp() < 3 then
		local zcards = self.player:getHandcards()
		local use_slash, keep_jink, keep_anal, keep_weapon = false, false, false, false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
					self:useBasicCard(zcard, dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = { isDummy = true }
					self:useTrickCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(card) then
					local dummy_use = { isDummy = true }
					self:useEquipCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then 
						shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then
				 shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() 
					then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_anal then
					keep_anal = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) 
					then
					local dummy_use = { isDummy = true }
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end		
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then
		 table.insert(use_cards, sgs.Sanguosha:getCard(unpreferedCards[index])) end
	end

	if #use_cards > 0 then
		local uselast = {}
		for _,cc in ipairs(use_cards) do
			if cc:isRed() then
				table.insert(uselast,cc:getId())
			end
			if #uselast == 2 then break end
		end
		use.card = sgs.Card_Parse("@TuhaoCard=" .. table.concat(uselast, "+"))
		return
	end
end

sgs.ai_use_value.TuhaoCard = 9
sgs.ai_use_priority.TuhaoCard = 2.61
sgs.dynamic_value.benefit.TuhaoCard = true
sgs.ai_chaofeng.luwei = 2

function sgs.ai_cardneed.tuhao(to, card)
	return not card:isKindOf("Jink")
end
--酱油
sgs.ai_skill_invoke["jiangyou"] = function(self, data)	
	if self.player:getLostHp() >1 then return false end
	local hp = self.player:getHp()
	local count = self.player:getHandcardNum()
	local cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards) do
		if card:isKindOf("Peach") and self.player:isWounded() then
			return false
		end
	end
	return hp >= count-2
end
sgs.ai_skill_playerchosen["jiangyou"] = function(self, targets)
	local target
	local n=0
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			if p:getHandcardNum()>n then
				n=p:getHandcardNum()
				target=p				
			end
		end		
	end
	if n>=2 then
		return target
	end
	return false
end
--女总
local nvzong_skill = {}
nvzong_skill.name = "nvzong"
table.insert(sgs.ai_skills, nvzong_skill)
nvzong_skill.getTurnUseCard = function(self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end
	if #equips == 0 then return end

	return sgs.Card_Parse("@NvzongCard=.")
end

sgs.ai_skill_use_func.NvzongCard = function(card, use, self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Armor") or card:isKindOf("Weapon") then
			if not self:getSameEquip(card) then
			elseif card:isKindOf("GudingBlade") and self:getCardsNum("Slash") > 0 then
				local HeavyDamage
				local slash = self:getCard("Slash")
				for _, enemy in ipairs(self.enemies) do
					if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy) and
						self:slashIsEffective(slash, enemy) and not self.player:hasSkill("jueqing") and
						 enemy:isKongcheng() then
							HeavyDamage = true
							break
					end
				end
				if not HeavyDamage then table.insert(equips, card) end
			else
				table.insert(equips, card)
			end
		elseif card:getTypeId() == sgs.Card_Equip then
			table.insert(equips, card)
		end
	end

	if #equips == 0 then return end

	local select_equip, target
	for _, friend in ipairs(self.friends_noself) do
		for _, equip in ipairs(equips) do
			if not self:getSameEquip(equip, friend) and 
			self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
		for _, equip in ipairs(equips) do
			if not self:getSameEquip(equip, friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end

	if not target then return end
	if use.to then
		use.to:append(target)
	end
	local nvzong = sgs.Card_Parse("@NvzongCard=" .. select_equip:getId())
	use.card = nvzong
end

sgs.ai_card_intention.NvzongCard = -80
sgs.ai_use_priority.NvzongCard = sgs.ai_use_priority.RendeCard + 0.1  -- 刘备二张双将的话，优先直谏
sgs.ai_cardneed.nvzong = sgs.ai_cardneed.equip
--大姐
sgs.ai_skill_invoke["dajie"] = function(self, data)
	if self.player:isKongcheng() or not self.player:canDiscard(self.player,"h") then return false end
	local move = data:toMoveOneTime()
	local from = findPlayerByObjectName(self.room, move.from:objectName())
	if self:isWeak() or not from or not self:isFriend(from)
		or (from:hasSkill("manjuan") and from:getPhase() == sgs.Player_NotActive)
		or self:needKongcheng(from, true) then return false end
	local skill_name = move.reason.m_skillName
	if skill_name == "rende" or skill_name == "nosrende" then return true end
	return from:getHandcardNum() < from:getHp()+2
end
--发布
local fabu_skill = {}
fabu_skill.name = "fabu"
table.insert(sgs.ai_skills, fabu_skill)
fabu_skill.getTurnUseCard = function(self)
	if self.player:getPile("bao"):isEmpty() then return end
	if self:isWeak(self.player) then return end
	if #self.enemies>#self.friends then return end
	return sgs.Card_Parse("@FabuCard=.")
end
sgs.ai_skill_use_func.FabuCard = function(card,use,self)
	if self.player:hasSkill("noswuyan|zhongyong") then use.card = card return end
	if (self.role == "lord" or self.role == "loyalist") and sgs.turncount <= 2 and 
		self.player:getSeat() <= 3 and self.player:aliveCount() > 5 then return end
	local value = 1
	local suf, coeff = 0.8, 0.8
	if self:needKongcheng() and self.player:getHandcardNum() == 1 or self.player:hasSkills("nosjizhi|jizhi|weikou") 
		then
		suf = 0.6
		coeff = 0.6
	end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local index = 0
		if self:isFriend(player) and AG_isEffective(card, player, self.player) then
			index = 1
		elseif self:isEnemy(player) and AG_isEffective(card, player, self.player) then
			index = -1
		end
		value = value + index * suf
		if value < 0 then return end
		suf = suf * coeff
	end
	use.card = card
end
--研发
local yanfa_skill={}
yanfa_skill.name="yanfa"
table.insert(sgs.ai_skills,yanfa_skill)
yanfa_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards)
	--cards=sgs.reverse(cards)
	if #cards == 0 then return nil end
	for _, card in ipairs(cards) do
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()
		if card:isKindOf("Weapon") then
			return sgs.Card_Parse(string.format("amazing_grace:yanfa[%s:%s]=%d", suit, point, id))
		elseif card:isKindOf("Armor") then
			return sgs.Card_Parse(string.format("god_salvation:yanfa[%s:%s]=%d", suit, point, id))
		elseif card:isKindOf("DefensiveHorse") then
			return sgs.Card_Parse(string.format("savage_assault:yanfa[%s:%s]=%d", suit, point, id))
		elseif card:isKindOf("OffensiveHorse") then
			return sgs.Card_Parse(string.format("archery_attack:yanfa[%s:%s]=%d", suit, point, id))			
		end		 			
	end
end
--集错
sgs.ai_skill_invoke.jicuo = function(self)
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.jicuo = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end
--收集
local shoujiv_skill = {}
shoujiv_skill.name = "shoujiv"
table.insert(sgs.ai_skills, shoujiv_skill)

shoujiv_skill.getTurnUseCard = function(self)
	if self.player:hasFlag("ForbidShouji") then return nil end
	if self.player:getKingdom() ~= "ping" then return nil end

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if acard:isKindOf("EquipCard") then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getEffectiveId()
	local card_str = "@ShoujiCard="..card_id
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use_func.ShoujiCard = function(card, use, self)
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("shouji") then
			if not friend:hasFlag("ShoujiInvoked") then
				if not friend:hasSkill("manjuan") then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	elseif self:getCardsNum("Slash", self.player, "he") >= 2 then --黄天对方
		for _,enemy in ipairs(self.enemies) do
			if enemy:hasLordSkill("shouji") then
				if not enemy:hasFlag("ShoujiInvoked") then
					if not enemy:hasSkill("manjuan") then
						if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and 
						not enemy:hasSkills("tuntian+zaoxian") then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:hasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:hasUsed("XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = self:getMaxCard(self.player) --最大点数的手牌
				if maxCard:getNumber() > card:getNumber() then --可以保证拼点成功
					self:sort(targets, "defense", true)
					for _,enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
								use.card = card
								enemy:setFlags("AI_shoujiPindian")
								if use.to then
									use.to:append(enemy)
								end
								break
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention.ShoujiCard = -80

sgs.ai_use_priority.ShoujiCard = 10
sgs.ai_use_value.ShoujiCard = 8.5
--禅道
sgs.ai_skill_choice["chandao"] = function(self, choices, data)
	local player = self.room:getTag("guojunfeng"):toPlayer()	
	if self:isEnemy(player) and self.player:getCards("he"):length()>self.player:getHp() then return "discardone"
	else return "letdraw" end
end
--帮扶要闪
sgs.ai_skill_invoke["bangfuask"] = function(self,data)
	local lord = self.room:getLord()
	if not lord:hasSkill("bangfu") then return false end
	local jink = 0
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Jink") then
			jink = jink + 1
		end
	end
	if jink >1 then return false end
	return true
end
sgs.ai_skill_cardask["@bangfuask"] = function(self,tohelp)
	local victim = tohelp:toPlayer()
	if victim:objectName() == self.player:objectName() then return "." end		
	if not self:isFriend(victim) then return "." end
	if self:needBear() then return "." end
	local bgm_zhangfei = self.room:findPlayerBySkillName("dahe")
	if bgm_zhangfei and bgm_zhangfei:isAlive() and victim:hasFlag("dahe") then
		for _, card in ipairs(self:getCards("Jink")) do
			if card:getSuit() == sgs.Card_Heart then
				return card:getId()
			end
		end
		return "."
	end
	return self:getCardId("Jink") or "."
end
--不安
sgs.ai_skill_invoke.buan = function(self, data)
	local effect = data:toSlashEffect()
	if self:isEnemy(effect.to) then
		if self:doNotDiscard(effect.to) then
			return false
		end
	end
	if self:isFriend(effect.to) then
		return self:needToThrowArmor(effect.to) or self:doNotDiscard(effect.to)
	end
	return not self:isFriend(effect.to)
end
--龙套
sgs.ai_skill_choice["longtao"] = function(self, choices, data)
	if self.player:isWounded() then
		local hp = self.player:getHp()
		local count = self.player:getHandcardNum()
		if hp >= count + 2 then
			return "draw"
		else
			return "recover"
		end
	end
	return "draw"
end
--友善
sgs.ai_skill_invoke["youshan"] = function(self, data)
	local damage = data:toDamage()
	local victim=damage.to	
	if self.role == "renegade" and (not victim:isLord())  and 
			sgs.current_mode_players["loyalist"] == sgs.current_mode_players["rebel"] then
		return false
	end
	return self:isFriend(victim)
end
--拾遗
sgs.ai_skill_invoke.shiyi = function(self)
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.shiyi = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end
--得意
sgs.ai_skill_invoke.deyi = function(self, data)
	local effect = data:toCardUse()
	local current = self.room:getCurrent()
	if effect.card:isKindOf("GodSalvation") and self.player:isWounded() then
		return false
	elseif effect.card:isKindOf("AmazingGrace") and
		(self.player:getSeat() - current:getSeat()) % (global_room:alivePlayerCount()) 
		< global_room:alivePlayerCount()/2 then
		return false
	else
		return true
	end
end
--胃口
function sgs.ai_cardneed.weikou(to, card)
	return card:isNDTrick()
end

sgs.weikou_keep_value = {
	Peach 		= 6,
	Analeptic 	= 5.9,
	Jink 		= 5.8,
	ExNihilo	= 5.7,
	Snatch 		= 5.7,
	Dismantlement = 5.6,
	IronChain 	= 5.5,
	SavageAssault=5.4,
	Duel 		= 5.3,
	ArcheryAttack = 5.2,
	AmazingGrace = 5.1,
	Collateral 	= 5,
	FireAttack	=4.9
}

sgs.ai_chaofeng.zhangzhining = 5
--耍赖
sgs.ai_skill_invoke.shualai = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if self:getOverflow(target) > 2 then return true end
		if self:doNotDiscard(target) then return true end
		return (self:hasSkills(sgs.lose_equip_skill, target) and not target:getEquips():isEmpty())
		  or (self:needToThrowArmor(target) and target:getArmor()) or self:doNotDiscard(target)
	end
	if self:isEnemy(target) then
		if self:doNotDiscard(target) then return false end
		return true
	end
	--self:updateLoyalty(-0.8*sgs.ai_loyalty[target:objectName()],self.player:objectName())
	return true
end

sgs.ai_choicemade_filter.cardChosen.shualai = function(player, promptlist, self)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from then
		local intention = 10
		local id = promptlist[3]
		local card = sgs.Sanguosha:getCard(id)
		local target = damage.from
		if self:needToThrowArmor(target) and self.room:getCardPlace(id) == sgs.Player_PlaceEquip and 
			card:isKindOf("Armor") then
			intention = -intention
		elseif self:doNotDiscard(target) then intention = -intention
		elseif self:hasSkills(sgs.lose_equip_skill, target) and not target:getEquips():isEmpty() and
			self.room:getCardPlace(id) == sgs.Player_PlaceEquip and card:isKindOf("EquipCard") then
				intention = -intention		
		elseif self:getOverflow(target) > 2 then intention = 0
		end
		sgs.updateIntention(player, target, intention)
	end
end

sgs.ai_skill_cardchosen.shualai = function(self, who, flags)
	local cards = sgs.QList2Table(who:getEquips())
	local handcards = sgs.QList2Table(who:getHandcards())
	if #handcards==1 and handcards[1]:hasFlag("visible") then table.insert(cards,handcards[1]) end

	for i=1,#cards,1 do
		if (cards[i]:getSuit() == suit and suit ~= sgs.Card_Spade) or
			(cards[i]:getSuit() == suit and suit == sgs.Card_Spade and cards[i]:getNumber() >= 2 and
			 cards[i]:getNumber()<=9) then
			return cards[i]
		end
	end
	return nil
end
--文艺
local wenyi_skill={}
wenyi_skill.name="wenyi"
table.insert(sgs.ai_skills,wenyi_skill)
wenyi_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local jink_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:wenyi[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.wenyi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return ("slash:wenyi[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:wenyi[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_use_priority.wenyi = 9

sgs.wenyi_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}
----------------------------------------------------------------------------

-----------------------------销售、前台、行政等-----------------
--后勤
sgs.ai_skill_invoke["houqin"] = function(self)
	local currentplayer = self.room:getTag("current"):toPlayer()
	if self:isEnemy(currentplayer) then		
		return false		
	else
		return true		
	end
end
--血崩
sgs.ai_skill_invoke["xuebeng"] = function (self,data)
	local lord = self.room:getLord()
	if self.role == "loyalist" and self:isWeak(lord) then
		return false
	end
	return true
end
--护岗
local hugang_skill={}
hugang_skill.name="hugang"
table.insert(sgs.ai_skills,hugang_skill)
hugang_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("HugangCard") then return nil end
	if self:isWeak(self.player) then return nil end
	local friends = 0
	local enemies = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isWounded() then
			if self:isFriend(p) then
				friends = friends + 1
			else
				enemies = enemies + 1
			end
		end
	end
	if friends == 0 then return nil end
	if friends < enemies then return nil end
	return sgs.Card_Parse("@HugangCard=.")
end

sgs.ai_skill_use_func.HugangCard=function(card,use,self)
	use.card=card
end

sgs.ai_use_priority.HugangCard = 2
--镜像
sgs.ai_skill_invoke["jingxiang"] = function(self,data)
	if self.player:isKongcheng() then return false end
	local damage = data:toDamage()
	local from = damage.from
	if self:isFriend(from) and (self:isWeak(from) or not self:isWeak(self.player)) then return false end
	return true
end
--得道
local dedao_skill = {}
dedao_skill.name = "dedao"
table.insert(sgs.ai_skills, dedao_skill)
dedao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("DedaoCard") then return nil end	
	if self.player:isNude() or not self.player:canDiscard(self.player,"he") then return nil end
	local first_found, second_found = false, false
	local can_invoke = false
	local first_card, second_card
	if self.player:getCardCount(true) >= 2 then
		local cards = self.player:getCards("he")		
		cards = sgs.QList2Table(cards)
		local tricks = {}
		for _, fcard in ipairs(cards) do			
			if fcard:getTypeId() == sgs.Card_TypeTrick and not fcard:isKindOf("ExNihilo") then
				table.insert(tricks,fcard:getId())
				if #tricks == 2 then break end
			end
		end
		if #tricks ==2 then
			return sgs.Card_Parse("@DedaoCard="..table.concat(tricks,"+"))
		end
		for _, fcard in ipairs(cards) do
			if not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getTypeId() == first_card:getTypeId() and
						not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo")) then
						second_card = scard
						second_found = true
						break
					end
				end
				if first_found and second_found then can_invoke = true break end
			end
		end
		if can_invoke then
			local cc = {}
			table.insert(cc,first_card:getId())
			table.insert(cc,second_card:getId())
			return sgs.Card_Parse("@DedaoCard="..table.concat(cc,"+"))
		end		
	end	
	return nil
end
sgs.ai_skill_use_func.DedaoCard=function(card,use,self)
	if #self.friends == 0 then return "." end
	self:sort(self.friends,"defense")
	use.card = card
	if use.to then
		use.to:append(self.friends[1])
	end
end

sgs.ai_use_priority.DedaoCard = 4.8
--发钱
local faqian_skill={}
faqian_skill.name="faqian"
table.insert(sgs.ai_skills,faqian_skill)
faqian_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)	
	if #cards == 0 then return nil end
	for _, card in ipairs(cards) do
		local suit = card:getSuitString()
		local point = card:getNumberString()
		local id = card:getId()		
		if card:getSuit() == sgs.Card_Heart then
			return sgs.Card_Parse(string.format("amazing_grace:faqian[%s:%s]=%d", suit, point, id))			
		end		 			
	end
end
--补贴
sgs.ai_skill_invoke["butie"] = function(self,data)
	local  damage = data:toDamage()
	local to = damage.to
	return self:isFriend(damage.to)
end
--收缴
sgs.ai_skill_use["@@shoujiao"] = function(self, prompt, method)
	self:sort(self.enemies, "defense")
	local targets = {}
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")
	local zhaoxingyan = self.room:findPlayerBySkillName("shoujiao")
	local sunshangxiang = self.room:findPlayerBySkillName("xiaoji")	
	local add_player = function (player,isfriend)
		if player:isAllNude() or player:objectName()==self.player:objectName() then return #targets end
		if self:objectiveLevel(player) == 0 and player:isLord() and sgs.current_mode_players["rebel"] > 1 then 
			return #targets end
		if #targets==0 then 
			table.insert(targets, player:objectName())
		elseif #targets==1 then			
			if player:objectName()~=targets[1] then 
				table.insert(targets, player:objectName()) 
			end		
		end
		if isfriend and isfriend ==1 then
			self.player:setFlags("tuxi_isfriend_"..player:objectName())
		end
		return #targets
	end
	
	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and sgs.turncount ==1 and not lord:isAllNude() then
		add_player(self.room:getLord())
	end

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getMark("zhiji") == 0 and 
	jiangwei:getHandcardNum()== 1 
			and self:getEnemyNumBySeat(self.player,jiangwei) <= (jiangwei:getHp() >= 3 and 1 or 0) then
		if add_player(jiangwei,1) == 2  then 
			return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2])	end
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or 
		self:getEnemyNumBySeat(self.player,dengai) == 0 ) 
			and dengai:getMark("zaoxian") == 0 and dengai:getPile("field"):length() == 2 and 
			add_player(dengai,1) == 2 then 
		return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) 
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and 
	self:getEnemyNumBySeat(self.player,zhugeliang) > 0 then
		if zhugeliang:getHp() <= 2 then
			if add_player(zhugeliang,1) == 2 then 
				return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) end
		else
			local flag = string.format("%s_%s_%s","visible",self.player:objectName(),zhugeliang:objectName())					
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards == 1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or 
					cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang,1) == 2 then 
						return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) end
				end				
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum() == 1 and 
	self:getEnemyNumBySeat(self.player,luxun)>0 then	
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),luxun:objectName())
		local cards = sgs.QList2Table(luxun:getHandcards())
		if #cards==1 and (cards[1]:hasFlag("visible") or cards[1]:hasFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or 
				cards[1]:isKindOf("EquipCard") then
				if add_player(luxun,1)==2  then 
					return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) end
			end
		end	
	end

	if sunshangxiang and self:isFriend(sunshangxiang) and sunshangxiang:getCards("e"):length() >0 and 
	self:getEnemyNumBySeat(self.player,sunshangxiang)>0 then	
		if add_player(sunshangxiang,1)==2  then 
			return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) end
	end	

	for i=1,#self.friends,1 do
		local p=self.friends[i]
		local cards = sgs.QList2Table(p:getCards("j"))
		if #cards>0 then 
			if add_player(p)==2  then return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) end
		end
	end

	
	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _, card in ipairs(cards) do
			if (card:hasFlag("visible") or card:hasFlag(flag)) and (card:isKindOf("Peach") or 
				card:isKindOf("Nullification") or card:isKindOf("Analeptic") ) then
				if add_player(p)==2  then 
					return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) end
			end
		end
	end

	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		if self:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao"..
			"|longhun|xuanfeng|tianxiang|lijian", p) then
			if add_player(p)==2  then return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) end
		end
	end
	
	for i = 1, #self.enemies, 1 do
		local p = self.enemies[i]
		local x= p:getHandcardNum()
		local good_target=true				
		if x==1 and self:hasSkills(sgs.need_kongcheng,p) then good_target = false end
		if x>=2  and self:hasSkills("tuntian",p) then good_target = false end
		if good_target and add_player(p)==2 then 
			return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) end				
	end


	if luxun and add_player(luxun,(self:isFriend(luxun) and 1 or nil)) == 2 then 
		return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) 
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or 
		self:getEnemyNumBySeat(self.player,dengai) == 0 ) and add_player(dengai,1) == 2 then 
		return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2]) 
	end
	
	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other)>=0 and not self:hasSkills("tuntian",other) and 
			add_player(other)==2  then
			return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2])
		end
	end

	for _, other in sgs.qlist(others) do
		if self:objectiveLevel(other) >= 0 and not self:hasSkills("tuntian",other) and 
			add_player(other) == 2 and math.random(0, 5) <= 1 and not self:hasSkills("qiaobian") then
			return ("@ShoujiaoCard=.->%s+%s"):format(targets[1], targets[2])
		end
	end
	for _,enemy in ipairs(self.enemies) do		
		if add_player(enemy) == 1 then return ("@ShoujiaoCard=.->%s"):format(targets[1]) end
	end
	return "."
end
--加密
sgs.ai_skill_use["@@jiami"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	self:sort(self.enemies, "hp")
	if #self.enemies < 0 then return "." end

	local enemies_to_jiami = self.enemies
	for _, p in ipairs(self.enemies) do
		if not p:getPile("jiami"):isEmpty() then
			table.removeOne(enemies_to_jiami, p)
		end
	end

	for _, enemy in ipairs(enemies_to_jiami) do
		if not (self:needToLoseHp(enemy) and not self:hasSkills(sgs.masochism_skill, enemy)) then
			for _, c in ipairs(cards) do
				if c:isKindOf("EquipCard") then 
					return "@jiamiCard=" .. c:getEffectiveId() .. "->" .. enemy:objectName() end
			end
			for _, c in ipairs(cards) do
				if c:isKindOf("TrickCard") and not (c:isKindOf("Nullification") and 
					self:getCardsNum("Nullification") == 1) then
					return "@jiamiCard=" .. c:getEffectiveId() .. "->" .. enemy:objectName()
				end
			end
			for _, c in ipairs(cards) do
				if c:isKindOf("Slash") then
					return "@jiamiCard=" .. c:getEffectiveId() .. "->" .. enemy:objectName()
				end
			end
		end
	end
end

sgs.ai_skill_cardask["@jiami-give"] = function(self, data)
	local card_type = data:toString()
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	if self:needToLoseHp() and not self:hasSkills(sgs.masochism_skill) then return "." end
	self:sortByUseValue(cards)
	for _, c in ipairs(cards) do
		if c:isKindOf(card_type) and not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
			return "$" .. c:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_card_intention.jiamiCard = 30

sgs.jiami_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Nullification = 5,
	EquipCard = 4.9,
	TrickCard = 4.8
}
--许可
sgs.ai_skill_cardask["@xuke"] = function(self, data)
	local function getLeastValueCard(isRed)
		local offhorse_avail, weapon_avail
		for _, enemy in ipairs(self.enemies) do
			if self:canAttack(enemy, self.player) then
				if not offhorse_avail and self.player:getOffensiveHorse() and 
					self.player:distanceTo(enemy, 1) <= self.player:getAttackRange() then
					offhorse_avail = true
				end
				if not weapon_avail and self.player:getWeapon() and self.player:distanceTo(enemy) == 1 then
					weapon_avail = true
				end
			end
			if offhorse_avail and weapon_avail then break end
		end
		if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
		if self.player:getPhase() > sgs.Player_Play then
			local cards = sgs.QList2Table(self.player:getHandcards())
			self:sortByKeepValue(cards)
			for _, c in ipairs(cards) do
				if self:getKeepValue(c) < 8 and not self.player:isJilei(c) and not self:isValuableCard(c) then
				 return "$" .. c:getEffectiveId() end
			end
			if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then 
				return "$" .. self.player:getOffensiveHorse():getEffectiveId() end
			if weapon_avail and not self.player:isJilei(self.player:getWeapon()) and 
				self:evaluateWeapon(self.player:getWeapon()) < 5 then 
				return "$" .. self.player:getWeapon():getEffectiveId() end
		else
			local slashc
			local cards = sgs.QList2Table(self.player:getHandcards())
			self:sortByUseValue(cards, true)
			for _, c in ipairs(cards) do
				if self:getUseValue(c) < 6 and not self:isValuableCard(c) and not self.player:isJilei(c) then
					if isCard("Slash", c, self.player) then
						if not slashc then slashc = c end
					else
						return "$" .. c:getEffectiveId()
					end
				end
			end
			if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then
			 return "$" .. self.player:getOffensiveHorse():getEffectiveId() end
			if isRed and slashc then return "$" .. slash:getEffectiveId() end
		end
	end
	local use = data:toCardUse()
	local slash = use.card
	local slash_num = 0
	if use.from:objectName() == self.player:objectName() then slash_num = self:getCardsNum("Slash") else
	 slash_num = getCardsNum("Slash", use.from) end
	if self:isEnemy(use.from) and use.m_addHistory and not self:hasCrossbowEffect(use.from) and
	 slash_num > 0 then return "." end
	if (slash:isRed() and not (self.player:hasSkill("manjuan") and self.player:getPhase() == sgs.Player_NotActive))
		or (use.m_reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY and use.m_addHistory and 
			self:isFriend(use.from) and slash_num >= 1) then
		local str = getLeastValueCard(slash:isRed())
		if str then return str end
	end
	return "."
end
--接送
local jiesong_skill = {}
jiesong_skill.name = "jiesong"
table.insert(sgs.ai_skills, jiesong_skill)
jiesong_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("@JiesongCard=.")
end

sgs.ai_skill_use_func.JiesongCard = function(card,use,self)
	self:sort(self.friends, "handcard")
	for _, friend in ipairs(self.friends) do
		if friend:getMark("jiesong" .. self.player:objectName()) == 0 and friend:getHandcardNum() < friend:getHp() 
		and not (friend:hasSkill("manjuan") and self.room:getCurrent() ~= friend) then
			if not (friend:hasSkill("haoshi") and friend:getHandcardNum() <= 1 and friend:getHp() >= 3) then
				use.card = sgs.Card_Parse("@JiesongCard=.")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end

	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("jiesong" .. self.player:objectName()) == 0 and enemy:getHandcardNum() > enemy:getHp() and
		 not enemy:isNude()
		  and not self:doNotDiscard(enemy, "he", nil, 2, true) then
			use.card = sgs.Card_Parse("@JiesongCard=.")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_value.JiesongCard = 3
sgs.ai_use_priority.JiesongCard = 3

sgs.ai_card_intention.JiesongCard = function(self, card, from, to)
	sgs.updateIntention(from, to[1], to[1]:getHandcardNum() > to[1]:getHp() and 80 or -80)
end
--制图
local zhitu_skill = {}
zhitu_skill.name = "zhitu"
table.insert(sgs.ai_skills,zhitu_skill)
zhitu_skill.getTurnUseCard = function(self)
	if self.player:getMark("used")>0 or self.player:isKongcheng()  then return nil end
	if self.player:property("card"):toInt()<=0 then return nil end
	local id = self.player:property("card"):toInt()
	if id<=0 then return nil end
	local  card = sgs.Sanguosha:getCard(id)	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local lastcard = sgs.Sanguosha:cloneCard(card:objectName())
	lastcard:setSkillName("zhitu")
	lastcard:addSubcard(cards[1])
	return lastcard
 end
--仁义
function sgs.ai_cardsview_valuable.renyi(self, class_name, player)
	if class_name == "Peach" and not player:isKongcheng() then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then 
			return nil end
		if dying:hasSkill("manjuan") and dying:getPhase() == sgs.Player_NotActive then
			local peach_num = 0
			if not player:hasFlag("Global_PreventPeach") then
				for _, c in sgs.qlist(player:getCards("he")) do
					if isCard("Peach", c, player) then peach_num = peach_num + 1 end
					if peach_num > 1 then return nil end
				end
			end
		end
		if self:playerGetRound(dying) < self:playerGetRound(self.player) and dying:getHp() < 0 then 
			return nil end
		if not player:faceUp() then
			if player:getHp() < 2 and (getCardsNum("Jink", player) > 0 or 
				getCardsNum("Analeptic", player) > 0) then return nil end
			return "@RenyiCard=."
		else
			if not dying:hasFlag("Global_PreventPeach") then
				for _, c in sgs.qlist(player:getHandcards()) do
					if not isCard("Peach", c, player) then return nil end
				end
			end
			return "@RenyiCard=."
		end
		return nil
	end
end

function sgs.ai_cardsview.renyi(self, class_name, player)
	if class_name == "Peach" and not player:isKongcheng() then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then 
			return nil end
		if player:getHp() < 2 and (getCardsNum("Jink", player) > 0 or 
			getCardsNum("Analeptic", player) > 0) then return nil end
		if not self:isWeak(player) then return "@RenyiCard=." end
		return nil
	end
end

sgs.ai_card_intention.RenyiCard = sgs.ai_card_intention.Peach
--和气
sgs.ai_skill_invoke.heqi = function(self,data)
	local damage = data:toDamage()
	local from = damage.from
	local to = damage.to
	if from:objectName() == to:objectName() then return false end 
	if from:objectName() == self.player:objectName() and to:objectName()~=self.player:objectName() then
		if self:isFriend(to) then return true end
		return false
	elseif to:objectName() == self.player:objectName() and from:objectName()~=self.player:objectName() then
		if self.player:isKongcheng() then return false end
		for _,card in sgs.qlist(self.player:getHandcards()) do
			if not card:isKindOf("Peach") then
				return true				
			end
		end
		return false
	end
	return false		
end
--雷厉
sgs.ai_skill_invoke.leili = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return false end

	local zj = self.room:findPlayerBySkillName("guidao")
	if zj and self:isEnemy(zj) and self:canRetrial(zj) then return false end

	if target:hasArmorEffect("EightDiagram") and not IgnoreArmor(self.player, target) then return true end
	if target:hasLordSkill("hujia") then
		for _, p in ipairs(self.enemies) do
			if p:getKingdom() == "wei" and (p:hasArmorEffect("EightDiagram") or p:getHandcardNum() > 0) then
			 return true end
		end
	end
	if target:hasSkill("longhun") and target:getHp() == 1 and self:hasSuit("club", true, target) then 
		return true end

	if target:isKongcheng() or (self:getKnownNum(target) == target:getHandcardNum() and 
		getKnownCard(target, "Jink", true) == 0) then return false end
	return true
end
sgs.ai_chaofeng.limingsheng = 1 
--忽悠
local huyou_skill = {}
huyou_skill.name= "huyou"
table.insert(sgs.ai_skills,huyou_skill)
huyou_skill.getTurnUseCard=function(self)
	if self.player:isKongcheng() or self.player:hasUsed("HuyouCard") then return nil end
	local lord = self.room:getLord()
	local peach = 0
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") then peach = peach + 1 break end
	end
	if lord and self:isWeak(lord) and self.role == "loyalist" and peach ==0 then return nil end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	return sgs.Card_Parse("@HuyouCard="..cards[1]:getId())
end

sgs.ai_skill_use_func.HuyouCard = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.HuyouCard = 4
sgs.ai_use_priority.HuyouCard = 4

--奔走
local benzou_skill = {}
benzou_skill.name= "benzou"
table.insert(sgs.ai_skills,benzou_skill)
benzou_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("BenzouCard") then
		return sgs.Card_Parse("@BenzouCard=.")
	end
end

sgs.ai_skill_use_func.BenzouCard = function(card, use, self)
	local weapon = self.player:getWeapon()
	if weapon then
		local hand_weapon, cards
		cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:isKindOf("Weapon") then
				hand_weapon = card
				break
			end
		end
		self:sort(self.enemies)
		self.equipsToDec = hand_weapon and 0 or 1
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and 
				self:damageIsEffective(enemy) then
				if hand_weapon and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
					use.card = sgs.Card_Parse("@BenzouCard=" .. hand_weapon:getId())
					if use.to then
						use.to:append(enemy)
					end
					break
				end
				if self.player:distanceTo(enemy) <= 1 then
					use.card = sgs.Card_Parse("@BenzouCard=" .. weapon:getId())
					if use.to then
						use.to:append(enemy)
					end
					return
				end
			end
		end
		self.equipsToDec = 0
	else
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and 
				self:damageIsEffective(enemy) then
				if self.player:distanceTo(enemy) <= self.player:getAttackRange() and 
					self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 then
					use.card = sgs.Card_Parse("@BenzouCard=.")
					if use.to then
						use.to:append(enemy)
					end
					return
				end
			end
		end
	end
end

sgs.ai_use_value.BenzouCard = 2.5
sgs.ai_card_intention.BenzouCard = 80
sgs.dynamic_value.damage_card.BenzouCard = true
sgs.ai_cardneed.benzou = sgs.ai_cardneed.weapon

sgs.benzou_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}

sgs.ai_chaofeng.xiongyi = 2
---------------------------------------------------------------------------------------
--------------------------------老总们---------------------------------------------
--远见跳过阶段
sgs.ai_skill_invoke["#yuanjianskip"] = function(self,data)
	if self.player:getPile("zhan"):isEmpty() then return false end
	local currentplayer = self.room:getTag("current"):toPlayer()
	if self:isFriend(currentplayer) then return false end
	--local cards = currentplayer:getJudgingArea()
	if currentplayer:containsTrick("indulgence") then
		return false
	else
		return currentplayer:getHandcardNum()+2 >currentplayer:getHp()
	end
end
--老板
function sgs.ai_slash_prohibit.laoban(self, to, card, from)
	local lord = self.room:getLord()
	if not lord then return false end
	if to:isLord() then return false end
	for _, askill in sgs.qlist(lord:getVisibleSkillList()) do
		if askill:objectName() ~= "laoban" and askill:isLordSkill() then
			local filter = sgs.ai_slash_prohibit[askill:objectName()]
			if  type(filter) == "function" and filter(self, to, card, from) then return true end
		end
	end
end

sgs.ai_skill_use["@jijiang"] = function(self, prompt)
	if self.player:hasFlag("Global_JijiangFailed") then return "." end
	local card = sgs.Card_Parse("@JijiangCard=.")
	local dummy_use = { isDummy = true }
	self:useSkillCard(card, dummy_use)
	if dummy_use.card then
		local jijiang = {}
		if sgs.jijiangtarget then
			for _, p in ipairs(sgs.jijiangtarget) do
				table.insert(jijiang, p:objectName())
			end
			return "@JijiangCard=.->" .. table.concat(jijiang, "+")
		end
	end
	return "."
end

--加薪
local jiaxin_skill = {}
jiaxin_skill.name = "jiaxin"
table.insert(sgs.ai_skills, jiaxin_skill)
jiaxin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("JiaxinCard") then return nil end
	if #self.friends_noself == 0 then return nil end
	if self.player:isKongcheng() or not self.player:canDiscard(self.player,"h") then return nil end
	if self:isWeak(self.player) then return nil end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	return sgs.Card_Parse("@JiaxinCard=%d",cards[1]:getId())
end
sgs.ai_skill_use_func.JiaxinCard=function(card,use,self)
	self:sort(self.friends_noself,"defense")
	use.card = card	
	if use.to then
		use.to:append(self.friends_noself[1])
	end
end
sgs.ai_use_priority.JiaxinCard = 4.8

--绩效
local jixiao_skill = {}
jixiao_skill.name = "jixiao"
table.insert(sgs.ai_skills, jixiao_skill)
jixiao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("JixiaoCard") then return nil end
	if #self.enemies == 0 then return nil end
	if self.player:isNude() or not self.player:canDiscard(self.player,"he") then return nil end
	if self:isWeak(self.player) then return nil end
	local first_found, second_found = false, false
	local can_invoke = false
	local first_card, second_card
	if self.player:getCardCount(true) >= 2 then
		local cards = self.player:getCards("he")		
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getTypeId() == first_card:getTypeId() and
						not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo")) then
						second_card = scard
						second_found = true
						break
					end
				end
				if first_found and second_found then can_invoke = true break end
			end
		end
		if can_invoke then
			local cc = {}
			table.insert(cc,first_card:getId())
			table.insert(cc,second_card:getId())
			return sgs.Card_Parse("@JixiaoCard="..table.concat(cc,"+"))
		end	
	end	
	return nil
end
sgs.ai_skill_use_func.JixiaoCard=function(card,use,self)
	use.card = card
end

sgs.ai_skill_use["@@jixiaoask"] = function(self, prompt, method)
	if self.player:getHandcardNum() <2 then return "." end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slash,jink = false,false
	local slashcard,jinkcard
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") then slash = true slashcard = card:getId() end
		if card:isKindOf("Jink") then jink = true jinkcard = card:getId() end
		if slash and jink then break end
	end
	if not (slash and jink) then return "." end
	return ("$%d+%d"):format(slashcard,jinkcard)
end

sgs.ai_skill_choice["jixiaogood"] = function(self, choices, data)
	local hp = self.player:getHp()
	local count = self.player:getHandcardNum()
	if hp >= count + 2 then
		return "draw"
	else
		return "recover"
	end
end

sgs.ai_skill_choice["jixiaobad"] = function(self, choices, data)
	local hp = self.player:getHp()
	local count = self.player:getCardCount(true)
	local peach=0
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") then peach = peach + 1 end
	end
	if peach >=2 then return "damage" end
	if hp >= count + 2 then
		return "damage"
	else
		return "discard1"
	end
end

sgs.ai_use_value.JixiaoCard = 5
sgs.ai_use_priority.JixiaoCard = 5.5
--文档
local wendang_skill = {}
wendang_skill.name = "wendang"
table.insert(sgs.ai_skills, wendang_skill)
wendang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("WendangCard") then return nil end	
	local can_invoke = false
	for _,friend in ipairs(self.friends_noself) do 
		if 	not friend:faceUp() then can_invoke = true  break end
	end
	for _,enemy in ipairs(self.enemies) do 
		if not enemy:isKongcheng() and enemy:canDiscard(enemy,"h") then can_invoke = true  break end
	end
	if not can_invoke then return nil end
	return sgs.Card_Parse("@WendangCard=.")
end
sgs.ai_skill_use_func.WendangCard=function(card,use,self)
	local targets = {}
	for _,friend in ipairs(self.friends_noself) do 
		if 	not friend:faceUp()  and friend:isKongcheng() and friend:canDiscard(friend,"h") then 
			use.card = card 
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
	for _,enemy in ipairs(self.enemies) do 
		if not enemy:isKongcheng() and enemy:canDiscard(enemy,"h") and enemy:faceUp() then 
			table.insert(targets,enemy)
		end
	end
	if #targets == 0 then return end
	self:sort(targets,"defense")	
	use.card = card
	if use.to then
		use.to:append(targets[1])
	end
end
sgs.ai_skill_discard["wendang"] = function(self)
	if self.player:isKongcheng() then return {} end
	local room = self.player:getRoom()
	local suit = room:getTag("suit"):toString()
	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)
    local card_same = {} 
    local card_diff = {}
    for _,c in ipairs(handcards) do 
    	if c:getSuitString() == suit then
    		table.insert(card_same,c:getEffectiveId())
    		break
    	else
    		table.insert(card_diff,c:getEffectiveId())
    		break
    	end
    end
    if self.player:faceUp() then
	    if #card_same>0 then 
	    	return card_same
	    else	    	
	    	return card_diff    	
	    end
	else
		if #card_diff>0 then
			return card_diff
		else
			return card_same
		end
	end
end

sgs.ai_use_value.WendangCard = 10
sgs.ai_use_priority.WendangCard = 10
--指导
sgs.ai_skill_playerchosen.zhidao = function(self, targets)
	if self.top_draw_pile_id then
		local card = sgs.Sanguosha:getCard(self.top_draw_pile_id)
		if card:isKindOf("EquipCard") then
			self:sort(self.friends, "hp")
			for _, friend in ipairs(self.friends) do
				if (not self:getSameEquip(card, friend) or card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse"))
					and not (card:isKindOf("Armor") and (friend:hasSkills("bazhen|yizhong") or self:evaluateArmor(card, friend) < 0)) then
					return friend
				end
			end
			if not (card:isKindOf("Armor") and (self.player:hasSkills("bazhen|yizhong") or self:evaluateArmor(card) < 0))
				and not (card:isKindOf("Weapon") and self.player:getWeapon() and self:evaluateWeapon(card) < self:evaluateWeapon(self.player:getWeapon()) - 1) then
				return self.player
			end
		else
			local cards = { card }
			local player = self:getCardNeedPlayer(cards)
			if player then
				return player
			else
				self:sort(self.friends)
				for _, friend in ipairs(self.friends) do
					if not self:needKongcheng(friend, true) and not (friend:hasSkill("manjuan") and friend:getPhase() == sgs.Player_NotActive) then return friend end
				end
			end
		end
	else
		self:sort(self.friends)
		for _, friend in ipairs(self.friends) do
			if not self:needKongcheng(friend, true) and not (friend:hasSkill("manjuan") and friend:getPhase() == sgs.Player_NotActive) then return friend end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.zhidao = -60

--组织
sgs.ai_skill_playerchosen.zuzhi = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "handcard")
	local enemy
	for _, p in ipairs(targetlist) do
		if self:isEnemy(p) and not (p:getHandcardNum() == 1 and (p:hasSkill("kongcheng") or 
			(p:hasSkill("zhiji") and p:getMark("zhiji") == 0))) then
			if p:hasSkills(sgs.cardneed_skill) then return p
			elseif not enemy and not self:canLiuli(p, self.friends_noself) then enemy = p end
		end
	end
	if enemy then return enemy end
	targetlist = sgs.reverse(targetlist)
	local friend
	for _, p in ipairs(targetlist) do
		if self:isFriend(p) then
			if (p:hasSkill("kongcheng") and p:getHandcardNum() == 1) or (p:getCardCount(true) >= 2 and
			 self:canLiuli(p, self.enemies)) then return p
			elseif not friend and getCardsNum("Jink", p) >= 1 then friend = p end
		end
	end
	return friend
end

sgs.ai_skill_cardask["@zuzhi-give"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		local e_card = sgs.Sanguosha:getEngineCard(card:getEffectiveId())
		if e_card:isKindOf("Jink")
			and not (target and target:isAlive() and target:hasSkill("wushen") and 
				(e_card:getSuit() == sgs.Card_Heart or (target:hasSkill("hongyan") and 
					e_card:getSuit() == sgs.Card_Spade))) then
			return "$" .. card:getEffectiveId()
		end
	end
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) and self:getKeepValue(card) < 5 then 
			return "$" .. card:getEffectiveId() end
	end
	return "$" .. cards[1]:getEffectiveId()
end

function sgs.ai_slash_prohibit.zuzhi(self, to, card, from)
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	for _, friend in ipairs(self:getFriendsNoself(from)) do
		if not to:isKongcheng() and not (to:getHandcardNum() == 1 and (to:hasSkill("kongcheng") or
		 (to:hasSkill("zhiji") and to:getMark("zhiji") == 0))) then return true end
	end
end

