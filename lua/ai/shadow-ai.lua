--Áõ±¸
--ÈÊµÂ
local Y_rende_skill={}
Y_rende_skill.name="Y_rende"
table.insert(sgs.ai_skills,Y_rende_skill)
Y_rende_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum() <= 1  then return end
	for _, player in ipairs(self.friends_noself) do
		if ((player:hasSkill("haoshi") and not player:containsTrick("supply_shortage")) 
			or player:hasSkill("longluo") or (not player:containsTrick("indulgence") and  player:hasSkill("yishe"))
			and player:faceUp()) or player:hasSkill("jijiu") then
			return sgs.Card_Parse("#Y_rendecard:.:") 
		end
	end
	if self.player:usedTimes("#Y_rendecard") < 2 or self:getOverflow() > 0  then
		return sgs.Card_Parse("#Y_rendecard:.:") 
	end
	if self.player:getLostHp() >0 then
		return sgs.Card_Parse("#Y_rendecard:.:") 
	end
end
 
sgs.ai_skill_use_func["#Y_rendecard"]=function(card,use,self)
    local rd_card = {}
	local x = self.player:getHandcardNum()
	local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards)
	self:sort(self.friends_noself,"defense")
	if x>2 then
	    for _,friend in ipairs(self.friends_noself) do
            for _,card in ipairs(cards) do
                use.card = sgs.Card_Parse("#Y_rendecard:"..card:getId()..":")
			    if use.to then use.to:append(friend) end
			    return
            end
		end
    elseif x==2 then
		for _,friend in ipairs(self.friends_noself) do
		    local i=0
		    for _, acard in ipairs(cards) do
	            table.insert(rd_card, acard:getId())
			    i=i+1
			    if i==2 then
		            use.card = sgs.Card_Parse("#Y_rendecard:"..table.concat(rd_card, "+")..":")
                    if use.to then use.to:append(friend) end
		            return
				end
		    end
		end
    end
end	
sgs.ai_use_value.Y_rendecard = 8.5
sgs.ai_use_priority.Y_rendecard = 8.8

--²½Á¶Ê¦
--²»¶Ê
local Y_anxu_skill={}
Y_anxu_skill.name="Y_anxu"
table.insert(sgs.ai_skills,Y_anxu_skill)
Y_anxu_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("#Y_anxucard") then return end
    return sgs.Card_Parse("#Y_anxucard:.:") 
end
	
sgs.ai_skill_use_func["#Y_anxucard"]=function(card,use,self)
	self:sort(self.friends,"hp")
	for _,friend in ipairs(self.friends) do
	    if friend:isWounded() then 
	        --if not friend:containsTrick("indulgence") then
	        local cards=self.player:getHandcards()
		    for _,card in sgs.qlist(cards) do
			    if not card:isKindOf("Peach") and not card:isKindOf("Shit") then
			        use.card = sgs.Card_Parse("#Y_anxucard:"..card:getId()..":")
			        if use.to then 
				        use.to:append(friend) 
				    end
			        return
				end
			end
            --end
        end
	end	
end

sgs.ai_skill_discard.Y_anxu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {} 
    local cards = self.player:getCards("he")
	local x = self.player:getCardCount(true)
	cards=sgs.QList2Table(cards)
	self:sortByDynamicUsePriority(cards,true)
	local i
    for _, card in ipairs(cards) do
	    table.insert(to_discard, card:getId())
		i=i+1
        if i == discard_num then break end
	end
    return to_discard
end 
sgs.ai_use_value.Y_anxucard = 9
sgs.ai_use_priority.Y_anxucard =4.2
sgs.dynamic_value.benefit.Y_anxucard = true

--ÂíÔÆðØ
--ÈÖ×°
local Y_rongzhuang_skill = {}
Y_rongzhuang_skill.name="Y_rongzhuang"
table.insert(sgs.ai_skills, Y_rongzhuang_skill)
Y_rongzhuang_skill.getTurnUseCard=function(self)
	local hcards = self.player:getCards("h")
	local ecards = self.player:getCards("e")
	ecards = sgs.QList2Table(ecards)
	hcards = sgs.QList2Table(hcards)
	local x = self.player:getEquips():length()
	if x~=0 then
	    local slashcard
		self:sortByUseValue(hcards,true)
	    for _,hcard in ipairs(hcards) do
		    for _,ecard in ipairs(ecards) do
                if ecard:getSuit() == hcard:getSuit() then
                    slashcard = hcard break				
			    end
		    end
		    if slashcard then break end
	    end
	    if slashcard then 
	        local card_str =("slash:Y_rongzhuang[%s:%s]=%d"):format(slashcard:getSuitString(), slashcard:getNumberString(), slashcard:getEffectiveId()) 
	        local slash = sgs.Card_Parse(card_str)
            assert(slash)
            return slash
        end
    end		
end

sgs.ai_view_as.Y_rongzhuang = function(card, player, card_place)
	if card_place ~= sgs.Player_PlaceHand then return end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId() 
	local hcards = player:getCards("h")
	local ecards= player:getCards("e")
	local x = player:getEquips():length()
	if player:getMark("RzMark")==2 then
	    if x > 0 then
			for _,hcard in sgs.qlist(hcards) do
			    local i=0
				for _,ecard in sgs.qlist(ecards) do
				    if ecard:getSuit() == hcard:getSuit() then
					    break
					end
                    if ecard:getSuit() ~= hcard:getSuit() then
                        i=i+1
				    end	
				end
				if i==x then
	                card=hcard
					return ("jink:Y_rongzhuang[%s:%s]=%d"):format(suit, number, card_id)
				end
			end
			return nil
		else
		    for _,hcard in sgs.qlist(hcards) do
			    card = hcard
			    return ("jink:Y_rongzhuang[%s:%s]=%d"):format(suit, number, card_id)
			end
		end
	elseif player:getMark("RzMark")==1 then 
		if x == 0 then return end
		for _,acard in sgs.qlist(hcards) do
			for _,bcard in sgs.qlist(ecards) do
                if bcard:getSuit() == acard:getSuit() then
                    card = acard  
					return ("slash:Y_rongzhuang[%s:%s]=%d"):format(suit, number, card_id)
				end
			end
		end	
	end
end

--³åÆï
sgs.ai_skill_invoke.Y_chongqi = function(self, data)
    local effect=data:toSlashEffect()
	return self:isEnemy(effect.to)
end

sgs.Y_mayunlu_keep_value = 
{
    Peach = 6,
    Analeptic = 5.4,
    ExNihilo = 5.9,
	snatch = 5.3,
	EightDiagram = 5.7,
	RenwangShield = 5.8,
	OffensiveHorse = 5.1,
	DefensiveHorse = 5.2,
	Indulgence = 5.6,
	Nullification = 5.5,
	Dismantlement = 5.1,
	Crossbow = 5.0,
	Jink = 4,
    Slash = 4.1,
    ThunderSlash = 4.5,
    FireSlash = 4.9,

}

--½ªÎ¬	
--Ö¾¼Ì		
sgs.ai_skill_invoke.Y_zhiji = function(self, data)
        return true 
	end
--ÌôÐÆ	
local Y_tiaoxin_skill={}
Y_tiaoxin_skill.name="Y_tiaoxin"
table.insert(sgs.ai_skills,Y_tiaoxin_skill)
Y_tiaoxin_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("#Y_tiaoxincard") then return end
	for _,enemy in ipairs(self.enemies) do
	    if enemy:distanceTo(self.player) <= enemy:getAttackRange() then
		    return sgs.Card_Parse("#Y_tiaoxincard:.:")
        end			
	end
end
	
sgs.ai_skill_use_func["#Y_tiaoxincard"]=function(card,use,self)
	self:sort(self.enemies,"threat")
	for _,enemy in ipairs(self.enemies) do
	    if enemy:distanceTo(self.player) <= enemy:getAttackRange() and
	    (self:getCardsNum("Slash", enemy) == 0 or self:getCardsNum("Jink") > 0 or self:getHp()>=2) and not enemy:isNude() then
	        use.card=sgs.Card_Parse("#Y_tiaoxincard:"..card:getId()..":")
		    if use.to then 
				use.to:append(enemy) 
	        end
	        return
		end
	end
end

--ÃÓÕê
--Ô®»¤
sgs.ai_skill_invoke.Y_huyouslash = function(self, data)
	for _, fr in ipairs(self.friends) do
	    if fr:getHandcardNum()<fr:getHp() then
		    return true
		end
	end
	return false
end

sgs.ai_skill_invoke.Y_huyoujink = function(self, data)
	for _, fr in ipairs(self.friends) do
	    if fr:isWounded() then
		    return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.Y_huyou= function(self, targets)
    for _, tar in sgs.qlist(targets) do
	    if self:isFriend(tar) then
		    return tar
		end
	end
end

--ÓÂ¾ö
sgs.ai_skill_invoke.Y_yongjue = function(self, data)
    if self.player:getRole()=="lord" then return false end 
    if #self.friends_noself <1 then return false end
	local x = self.player:getHandcardNum()
	if x == 1 then return true end
	local i=0
	for _,card in sgs.qlist(self.player:getCards("h")) do
	    if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
		    i=i+1
		end
	end
	if i>0 then return false end
	return true
end

sgs.ai_skill_playerchosen.Y_yongjue= function(self, targets)
    for _, friend in ipairs(self.friends_noself) do
	    if friend:hasSkill("longdan") then
		    return friend
		end
	end
	for _, tar in sgs.qlist(targets) do
	    if self:isFriend(tar) then
		    return tar
		end
	end
end

sgs.ai_skill_cardchosen.Y_yongjue = function(self, who, flags)
    local cards=self.player:getCards("h")
	cards=sgs.QList2Table(cards)
    self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
	    if card then 
		    self:setCardFlag(card:getId(),"tjcard")				
			break
		end
	end
	return card_for_Y_toujing(self, who, "tjcard")
end

--¸ÊÙ»
--ÉñÖÇ
local Y_shenzhi_skill={}
Y_shenzhi_skill.name="Y_shenzhi"
table.insert(sgs.ai_skills,Y_shenzhi_skill)
Y_shenzhi_skill.getTurnUseCard=function(self)
    if self.player:getHp()>=self.player:getHandcardNum() then return end
    if self.player:isWounded() then 
	    local card_str = ("peach:Y_shenzhi[no_suit:0]=.")
		local peach = sgs.Card_Parse(card_str)
        assert(peach)
        return peach
	end
end
	
function sgs.ai_cardsview.Y_shenzhi(self, class_name, player)
	if class_name == "Peach" then
	    local x = player:getHp()
		local y = player:getHandcardNum()
	    if x<0 then x=0 end
		if y>x then
		    return ("peach:Y_shenzhi[no_suit:0]=.")
		end
    end
end

--[[local Y_shenzhi_skill={}
Y_shenzhi_skill.name="Y_shenzhi"
table.insert(sgs.ai_skills,Y_shenzhi_skill)
Y_shenzhi_skill.getTurnUseCard=function(self)
    if not self.player:isWounded() then return end
	return sgs.Card_Parse("#Y_shenzhicard:.:")
end

sgs.ai_skill_use_func["#Y_shenzhicard"]=function(card,use,self)
	local x=self.player:getHandcardNum() 
	local y=self.player:getHp()
    if y<0 then y=0 end
	if x<=y then return end
	local cards=self.player:getCards("h")
	local pcard={}
	local i=0
	for _,card in sgs.qlist(cards) do
        if not card:isKindOf("Peach") then
            table.insert(pcard, card:getId())
			i=i+1
			if i==(x-y) then break end
		end
	end
	use.card=sgs.Card_Parse("#Y_shenzhicard:"..table.concat(pcard, "+")..":->")
	return 
end

sgs.ai_skill_invoke.Y_shenzhi = function(self, data)
    local dy = data:toDying()
	for _,card in sgs.qlist(self.player:getCards("h")) do
	    if card:isKindOf("Peach") then return false end
	end
	return not self:isEnemy(dy.who)
end	]]		

--ÊçÉ÷
sgs.ai_skill_invoke.Y_shushen = function(self, data)
    for _, friend in ipairs(self.friends) do
	    if friend:getHandcardNum()<friend:getHp() and not (friend:hasSkill("kongcheng") and friend:isKongcheng())then
		    return true
		end
    end	
    for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
            return true
		end
	end
end

sgs.ai_skill_playerchosen.Y_shushen = function(self, targets)
    self:sort(self.friends,"defense")
	for _, friend in ipairs(self.friends) do
	    if friend:getHandcardNum()<friend:getHp() and not (friend:hasSkill("kongcheng") and friend:isKongcheng())then
		    return friend
		end
    end	
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
            return enemy
		end
	end
end


--ÂÀÃÉ
--°×ÒÂ
sgs.ai_skill_invoke.Y_baiyi = function(self, data)
    if self.player:isNude() then return false end
    if (self:getCardsNum("JinK")==1 or self:getCardsNum("Peach")==1) and self.player:getHandcardNum()==1 then return false end
	return true
end

sgs.ai_skill_invoke.Y_baiyier = function(self, data)
	for _, enemy in ipairs(self.enemies) do 
        if not enemy:isNude() then
            return true
		end
	end
	for _, friend in ipairs(self.friends) do
        if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") or friend:containsTrick("lightning") then
		    return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.Y_baiyi = function(self, targets)
	for _, friend in ipairs(self.friends) do
        if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") then
            return friend
		end
		if friend:containsTrick("lightning") then
		    for _, enemy in ipairs(self.enemies) do
			    if enemy:hasSkill("guicai") or enemy:hasSkill("guidao") or enemy:hasSkill("guanxing") then				
			        return friend
				end
			end
		end
	end
	self:sort(self.enemies,"defense")
	for _, en in ipairs(self.enemies) do
		if not en:isNude() then
		    return en
		end
	end
end

--ÖÜÌ©
--Ô®¾È
sgs.ai_skill_invoke.Y_yuanjiu = function(self, data)
    local x = self.player:getPile("Y_yuanjiuPile"):length()
	local pcards=self.player:getPile("Y_yuanjiuPile")
	local can_peach=true
	if x>0 then 
		for _, acard in sgs.qlist(pcards) do
            for _, bcard in sgs.qlist(pcards) do
		        if acard~=bcard and sgs.Sanguosha:getCard(acard):getNumber()==sgs.Sanguosha:getCard(bcard):getNumber() then
					can_peach = false break
				end
			end
			if can_peach==false then break end
		end
	end
    local cards=self.player:getCards("h")
	local y = self.player:getHandcardNum()
	local dy = data:Dying()
	if can_peach==true then
	    if self:isFriend(dy.who) then
		    return true
		else 
		    return false
		end
	else
	    return true
	end
end
			
sgs.ai_skill_cardchosen.Y_yuanjiu = function(self, who, flags)
    local hcard = self.player:getCards("h")
	local pcard = self.player:getPile("Y_yuanjiuPile")
	local x = self.player:getPile("Y_yuanjiuPile"):length()
	local i=0
    for _, acard in sgs.qlist(hcard) do
		for _, bcard in sgs.qlist(pcard) do
		    local ccard = sgs.Sanguosha:getCard(bcard)
			if ccard:getNumber()~=acard:getNumber() then
				i=i+1
                if i==x then
                    self:setCardFlag(acard:getId(),"pcard")				
					return card_for_Y_yuanjiu(self, who, "pcard")
				end
			end
		end
	end
end

sgs.ai_skill_askforag.Y_yuanjiu = function(self, card_ids)
    for _, card_id in ipairs(card_ids) do
	    if sgs.Sanguosha:getCard(card_id):isKindOf("Peach")then
			return card_id
        end 
		if sgs.Sanguosha:getCard(card_id):isKindOf("Analeptic") and self.player:getHp()<1 then
		    return card_id
		end
    end	
    for i, card_id2 in ipairs(card_ids) do
        for j, card_id3 in ipairs(card_ids) do
            if i ~= j and sgs.Sanguosha:getCard(card_id2):getNumber() == sgs.Sanguosha:getCard(card_id3):getNumber() then
                return card_id2
            end
        end
    end
end

--º«µ±
--½â·³
jfskills = {"buqu","tuntian","quanji"}
jfpiles = {"buqu","field","power"}

local Y_jiefan_skill={}
Y_jiefan_skill.name="Y_jiefan"
table.insert(sgs.ai_skills,Y_jiefan_skill)
Y_jiefan_skill.getTurnUseCard=function(self)
    if self.player:hasUsed("#Y_jiefancard") then return nil end
    return sgs.Card_Parse("#Y_jiefancard:.:") 
end
    
sgs.ai_skill_use_func["#Y_jiefancard"]=function(card,use,self)
    use.card=card
    for _, friend in ipairs(self.friends) do
        if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") or friend:containsTrick("lightning") then
			if use.to then
                use.to:append(friend)
			end
			return
		end
		if friend:isWounded() then
		    if friend:getArmor() and friend:getArmor():isKindOf("SilverLion") then
			    if use.to then
                    use.to:append(friend)
				end
			    return
			end
		end
		if friend:hasSkill("xiaoji") or friend:hasSkill("xuanfeng") then
		    if friend:getEquips():length()>0 then
			    if use.to then
                    use.to:append(friend)
				end
			    return
			end
		end
		for i=1, 99, 1 do
	        if friend:hasSkill(jfskills[1]) and friend:getPile(jfpiles[1]):length()>0 then
		        if use.to then
                    use.to:append(friend) 
			    end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
	    for i=2, 99, 1 do
	        if enemy:hasSkill(jfskills[i]) and enemy:getPile(jfpiles[i]):length()>0 then
		        if use.to then
                    use.to:append(enemy) 
				end
			end
			return
		end
		if enemy:getEquips():length()>0 then
		    if not enemy:hasSkill("xiaoji") and not enemy:hasSkill("xuanfeng") then
	            for _,ecard in sgs.qlist(enemy:getCards("e")) do
		            if ecard:isKindOf("Armor") or ecard:isKindOf("DefensiveHorse") or ecard:isKindOf("Weapon")then
			            if use.to then
                            use.to:append(enemy)
						end
			            return
					end
				end
		    end
		end
	end
	if use.to then
        use.to:append(self.player)
	end
	return
end

--Öî¸ðèª
--»ºÊÍ		   
Y_huanshi_skill={}
Y_huanshi_skill.name="Y_huanshi"
table.insert(sgs.ai_skills,Y_huanshi_skill)
Y_huanshi_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("#Y_huanshicard") then return end
	if (#self.friends_noself + #self.enemies)<2 then return end
	return sgs.Card_Parse("#Y_huanshicard:.:")
end

sgs.ai_skill_use_func["#Y_huanshicard"]=function(card,use,self)
    use.card=card
	if #self.friends_noself>=1 then
	    local friends={}
	    for _,friend in ipairs(self.friends_noself) do
		    if not friend:isKongcheng() then
		        table.insert(friends, friend)
			end
	    end
        if #friends>=2 then
	        if use.to then
			    use.to:append(friends[1])
			    use.to:append(friends[2])
				return
		    end
	    elseif #friends==1 then
	        self:sort(self.enemies,"defense")
		    for _,enemy in ipairs(self.enemies) do
			    if not enemy:isKongcheng() then
				    if use.to then
					    use.to:append(enemy)
					    use.to:append(friends[1])
					    return
					end
				end
			end
		end
	end
	return nil 
end

--ºëÔ®
sgs.ai_skill_use["@@Y_hongyuan"] = function(self, prompt)
	local targets={}
	for _, friend in ipairs(self.friends) do
		if self.player:inMyAttackRange(friend) then
		    table.insert(targets, friend:objectName())
		end
	end
	return "#Y_hongyuancard:.:->".. table.concat(targets, "+")
end

--Áõ±í
--×ÔÊØ
sgs.ai_skill_invoke.Y_zishou = function(self,data)
    local x = self.player:getLostHp()
	local y = self.player:getHp()
	local j,s,p,n= 0,0,0,0
    for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Jink") then 
		    j = j + 1
		elseif card:isKindOf("Slash") then
		    s = s + 1
		elseif card:isKindOf("Nullification") then
			n = n + 1
		elseif card:isKindOf("Peach") then
			p = p + 1
		end
	end
	if x>=2 then return true
	elseif x==1 then
	    if s>0 and self.player:canSlash() then
		    if y>=(j+s+n) then 
			    return true 
			end
        elseif y>(j+s+n) then 
		    return true
        end			
    elseif x<1 then
		if s>0 and self.player:canSlash() then
			if (y-(j+s+n+p))>=2 then 
			    return true 
			end
		elseif (y-(j+s+n+p))>2 then 
		    return true
		end
	end
	return false
end

--ÑøÕþ

sgs.ai_skill_use["@@Y_yangzheng"] = function(self, prompt)
    if self.player:getMark("Y_yzRec")==1 then return end
	if #self.friends_noself <1 then return end
    local x = self.player:getHandcardNum()
    local y = self.player:getHp()
    if x < y then return end
	local cards = self.player:getCards("h")
	self:sort(self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself) do
		if not friend:containsTrick("indulgence")then
			for _,card in sgs.qlist(cards) do
			    return "#Y_yangzhengcard:"..card:getId()..":->".. friend:objectName()
			end
		end
	end
end

--Â½Ñ·
--·ÙÓª
Y_fenying_skill={}
Y_fenying_skill.name="Y_fenying"
table.insert(sgs.ai_skills,Y_fenying_skill)
Y_fenying_skill.getTurnUseCard=function(self)
    for _,en in ipairs(self.enemies) do
		if not en:isKongcheng() and en:getHandcardNum()<self.player:getHandcardNum() 
		and (en:getHandcardNum()<3 or ((self.player:getHandcardNum()-self.player:getHp())- en:getHandcardNum())>-1) then
	        return sgs.Card_Parse("#Y_fenyingcard:.:")
		end
	end
	return 
end

sgs.ai_skill_use_func["#Y_fenyingcard"]=function(card,use,self)
	local tar
	self:sort(self.enemies,"defense")
	for _,en in ipairs(self.enemies) do
		if not en:isKongcheng() and en:getHandcardNum()<self.player:getHandcardNum() then
		    tar=en break
		end
	end
	if tar then
	    local x=tar:getHandcardNum()
	    local fy_card = {}
	    local cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByDynamicUsePriority(cards,true)
	    local i=0
    	for _, acard in ipairs(cards) do
	        table.insert(fy_card, acard:getId())
		    i=i+1
		    if i==x then break end
	    end
	    use.card=sgs.Card_Parse("#Y_fenyingcard:"..table.concat(fy_card, "+")..":")
	    if use.to then
		    use.to:append(tar)
	    end
	    return
	end
end

sgs.ai_skill_invoke.Y_fenying = function(self, data)
    return true
end

--¶ÈÊÆ
sgs.ai_skill_invoke.Y_dushi= function(self, data)
    if self.player:getHandcardNum()<self.player:getHp() then
        return true
	else
		for _, en in ipairs(self.enemies) do
	        if not en:isNude() then
		        return true
		    end
		end
	    for _, fr in ipairs(self.friends) do
            if self:isFriend(fr) then
		        if fr:containsTrick("indulgence") or fr:containsTrick("supply_shortage") then 
                    return true
		        elseif fr:containsTrick("lightning") then
		            for _, fr in ipairs(self.friends) do
			            if fr:hasSkill("guicai") or fr:hasSkill("guidao") or fr:hasSkill("guanxing") then 
				            return false
					    end
                    end
					return true
                end
		    end
	    end
	end
	return false
end

function sgs.ai_slash_prohibit.Y_dushi(self, to)
    if to:getHandcardNum()==to:getHp() then return false end
    if to:getHandcardNum()>to:getHp() then
	    if to:getHp()>1 then return true end
	end
end

sgs.ai_skill_playerchosen.Y_dushi = function(self, targets)
    for _, t in sgs.qlist(targets) do
        if self:isFriend(t) then
		    if t:containsTrick("indulgence") or t:containsTrick("supply_shortage") then 
                return t
				
		    elseif t:containsTrick("lightning") then
		        local target=true
		        for _, fr in ipairs(self.friends) do
			        if fr:hasSkill("guicai") or fr:hasSkill("guidao") or fr:hasSkill("guanxing") then 
				        target=false
					end
                end
                if target==true then return t end
			end
	    elseif self:isEnemy(t) then
	        if t:getHandcardNum() == 1 and self.player:isWounded() then
		        return t
		    end
	    end
	end
	self:sort(self.enemies,"defense")
	for _, en in ipairs(self.enemies) do
		if not en:isNude() then 
		    return en 
		end
    end
end

--Â½¿¹
--Î§Ñß
sgs.ai_skill_invoke.Y_weiyan = function(self, data)
    for _, fr in ipairs(self.friends) do
	    if fr:containsTrick("indulgence") or fr:containsTrick("supply_shortage") or fr:containsTrick("lightning") then 
            return true 
		end
	end
	for _, en in ipairs(self.enemies) do
	    if not en:isNude() then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.Y_weiyan = function(self, targets)
    for _, t in sgs.qlist(targets) do
        if self:isFriend(t) then
		    if t:containsTrick("indulgence") or t:containsTrick("supply_shortage") then 
                return t
				
		    elseif t:containsTrick("lightning") then
		        local target=true
		        for _, fr in ipairs(self.friends) do
			        if fr:hasSkill("guicai") or fr:hasSkill("guidao") or fr:hasSkill("guanxing") then 
				        target=false
					end
                end
                if target==true then return t end
			end
	    elseif self:isEnemy(t) then
	        if t:getHandcardNum() == 1 and self.player:isWounded() then
		        return t
		    end
	    end
	end
	self:sort(self.enemies,"defense")
	for _, en in ipairs(self.enemies) do
		if not en:isNude() then 
		    return en 
		end
    end
end

--Ü÷Øü
--Ææ²ß
local Y_qice_skill={}
Y_qice_skill.name="Y_qice"
table.insert(sgs.ai_skills,Y_qice_skill)
Y_qice_skill.getTurnUseCard=function(self)
    local x = self.player:getCardCount(true)
	local y = self.player:getHp()
	local z = self.player:getHandcardNum()
	local hcards = self.player:getCards("h")
	local ecards = self.player:getCards("e")
	if x>=3 and (z-y)>=2 then
	    return sgs.Card_Parse("#Y_qicecard:.:") 
	else
	    local i=0
		for _, h in sgs.qlist(hcards) do
		    if h:isKindOf("Peach") then
			    i=i+1
			end
		end
		for _, e in sgs.qlist(ecards) do
		    if (e:isKindOf("DefensiveHorse") or e:isKindOf("EightDiagram") or e:isKindOf("RenwangShield")) then
			    i=i+1
			end
		end
        if (x-i) >= 3 then 
		    return sgs.Card_Parse("#Y_qicecard:.:") 
		end
	end
end

sgs.ai_skill_use["@@Y_qice"] = function(self, prompt)
    local qc_card = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local i=0
	self:sortByDynamicUsePriority(cards, true)
	for _, card in ipairs(cards) do
	    if card then
		    table.insert(qc_card, card:getId())
		    i=i+1
		end
		if i==3 then break end
	end
	if i~=3 then return end
	local mark = self.player:getMark("Y_qcmark")
	local cardname = sgs.Sanguosha:getCard(mark-1):objectName()
	if cardname=="ex_nihilo" then
	    return ("ex_nihilo:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="archery_attack" then
	    return ("archery_attack:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="savage_assault" then
	    return ("savage_assault:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="fire_attack" then
	    return ("fire_attack:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="dismantlement" then
	    return ("dismantlement:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="amazing_grace" then
	    return ("amazing_grace:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="collateral" then
	    return ("collateral:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="duel" then
	    return ("duel:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="snatch" then
	    return ("snatch:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="god_salvation" then
	    return ("god_salvation:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	elseif cardname=="iron_chain" then
	    return ("iron_chain:Y_qice[%s:%s]=%d+%d+%d"):format("nosuit", 0, qc_card[1],qc_card[2],qc_card[3])
	end
end

sgs.ai_skill_use_func["#Y_qicecard"]=function(card,use,self)
    use.card = card
end	

sgs.ai_skill_choice.Y_qice = function(self,choices)
    local x=self.player:getHandcardNum()
	local y=self.player:getHp()
	local good, bad, chai ,shun = 0,0,0,0
	local qicetrick = "savage_assault|archery_attack|ex_nihilo|god_salvation"
	local qicetricks = qicetrick:split("|")
	for i=1, #qicetricks do
		local forbiden = qicetricks[i]
		forbid = sgs.Sanguosha:cloneCard(forbiden, sgs.Card_NoSuit, 0)
		if self.player:isLocked(forbid) then return end
	end
	for _, friend in ipairs(self.friends) do
		if friend:isWounded() then
			good = good + 10/(friend:getHp())
			if friend:isLord() then good = good + 10/(friend:getHp()) end
		end
		if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") then
		    if self.player:distanceTo(friend)<=1 then 
			    shun=1 
			else 
			    chai=1 
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() then
			bad = bad + 10/(enemy:getHp())
			if enemy:isLord() then
				bad = bad + 10/(enemy:getHp())
			end
		end
		if enemy:getHandcardNum()<=1 and enemy:getHp()<=2 then
		    return "duel"
		end
		for _, e in sgs.qlist(enemy:getEquips()) do
		    if e:isKindOf("EightDiagram") or e:isKindOf("RenwangShield") or e:isKindOf("DefensiveHorse") then
			    if self.player:distanceTo(enemy)<=1 then 
				    shun=1 break
			    else 
				    chai=1 break
			    end
			end
        end
	end
	if good > bad then
		return "god_salvation"
    else
	    local aoe1 = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
		local aoe2 = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)    
	    if self:getAoeValue(aoe1) > 0 then
	        return "savage_assault"
	    elseif self:getAoeValue(aoe2) > 0 then
	        return "archery_attack" 
		end
	end
	if x>3 and self:getCardsNum("Jink") == 0 and self:getCardsNum("Peach") == 0 then
		return "ex_nihilo"
	elseif self:getCardsNum("Peach")<=(x-3) then 
	    return "ex_nihilo"
	elseif shun==1 then 
	    return "snatch"
	elseif chai==1 then 
	    return "dismantlement"
	end
end

--ÖÇÓÞ
sgs.ai_skill_invoke.Y_zhiyu = function(self, data)
    local cards = self.player:getCards("h")	
	local first
	local difcolor = 0
	for _,card in sgs.qlist(cards)  do
		if not first then first = card end
		if (first:isRed() and card:isBlack()) or (card:isRed() and first:isBlack()) then 
		    difcolor = 1 break
		end
	end
    local dm=data:toDamage()	
	if self:isFriend(dm.from) then
	    return difcolor == 1
	else
	    return true
	end
end

function sgs.ai_slash_prohibit.Y_zhiyu(self, to)
    if to:getHandcardNum()>=1 then return false end
	if to:getHp()==1 then return false end
	if self.player:getHp()>2 then return false end
    if to:getHandcardNum()<1 then return true end
	return true 
end

--ÀîÈå
--ð²É±
sgs.ai_skill_invoke.Y_zhensha = function(self, data)
    local player = data:toPlayer()
	return self:isEnemy(player)
end

--Ê¶ÆÆ
sgs.ai_skill_invoke.Y_shipo = function(self, data)
    for _, p in ipairs(self.enemies) do
	    if not p:isKongcheng() then  
	        return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.Y_shipo = function(self, targets)
    self:sort(self.enemies,"defense")
	for _, p in ipairs(self.enemies) do
	    if not p:isKongcheng() then
		    return p
		end
    end	
end

function sgs.ai_slash_prohibit.Y_shipo(self, to)
    if to:getHp()==1 then
	    return self:getCardsNum("Analpetic") + self:getCardsNum("Peach")>0
	end
	return self:getCardsNum("Jink")>0 and (self:getHandcardNum()-self:getCardsNum("Jink"))<2
end

--ÂÀÁáç²
--Îèêª
sgs.ai_skill_invoke.Y_wuji = function(self, data)
    if self.player:getHandcardNum()>2 or self.player:getHandcardNum()>self.player:getHp() then return true end
end

sgs.ai_skill_choice.Y_wuji = function(self,choices)
    local i=0
    for _,p in ipairs(self.enemies) do
	    if not (p:hasSkill("kongcheng") and p:isKongcheng()) then
		i=i+1
		end
	end
	if i>1 then 
	    return "addtar"
	else 
	    return "addjink"
	end
end

sgs.ai_skill_playerchosen.Y_wuji = function(self, targets)
	for _, p in sgs.qlist(targets) do
	    if self:isEnemy(p) then
		    return p
		end
    end	
end

--ÀÌÔÂ
sgs.ai_skill_invoke.Y_laoyue = true

--ÆÑÔª
--ÉñÖý
local Y_shenzhu_skill={}
Y_shenzhu_skill.name="Y_shenzhu"
table.insert(sgs.ai_skills, Y_shenzhu_skill)
Y_shenzhu_skill.getTurnUseCard = function(self)
    if self.player:isKongcheng() then return end
	if self.player:hasUsed("#Y_shenzhucard") then return end
    local sz=false
	for _, card in sgs.qlist(self.player:getCards("h")) do
		if not card:isKindOf("Peach") then
			sz=true break
		end
	end
	if self.player:getHandcardNum()>self.player:getHp() then sz=true end
	if sz==true then
	    return sgs.Card_Parse("#Y_shenzhucard:.:")
	end
end

sgs.ai_skill_use_func["#Y_shenzhucard"] = function(card, use, self)
    local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards,true)
	for _, card in ipairs(cards) do
	    if not card:isKindOf("Peach") then
			use.card = sgs.Card_Parse("#Y_shenzhucard:"..card:getId()..":")
	        return
		end
	end
end

sgs.ai_skill_invoke.Y_shenzhu = function(self, data)
    for _, f in ipairs(self.friends) do
	    if f:getMark("Y_shenzhu")==1 then return true end
	end
    return false
end

sgs.ai_skill_askforag.Y_shenzhu = function(self, card_ids)
    self:sortByKeepValue(cards_ids,true)
    for _, card_id in ipairs(card_ids) do
	    local card = sgs.Sanguosha:getCard(card_id)
		for _,p in ipairs(self.friends) do
		    if card:isKindOf("Armor") then
				if not p:getArmor() then return card:getEffectiveId() end
			elseif card:isKindOf("DefensiveHorse") then
				if not p:getDefensiveHorse() then return card:getEffectiveId() end
			elseif card:isKindOf("Weapon") then
			    if not p:getWeapon() then return card:getEffectiveId() end
			elseif card:isKindOf("OffensiveHorse") then
				if not p:getOffensiveHorse() then card:getEffectiveId() end
			end
		end
	end
end

sgs.ai_skill_playerchosen.Y_shenzhu= function(self, targets)
    for _, tar in sgs.qlist(targets) do
	    if self:isFriend(tar) then
		    return tar
		end
	end
end

--°ÙÁ¶
sgs.ai_skill_invoke.Y_bailian = function(self, data)
    return true
end

--»Æ³ÐÑå
--²ÅÅä
sgs.ai_skill_invoke.Y_caipei = function(self, data)
    for _, fr in ipairs(self.friends) do
	    if not fr:isKongcheng() then
		    return self:getCardsNum("Peach") < self.player:getHandcardNum() 
	    end
	end
end

sgs.ai_skill_playerchosen.Y_caipei= function(self, targets)
    local cur = self.room:getCurrent()
    if self:isFriend(cur) then 
	    return cur
	else
        for _, fr in ipairs(self.friends) do
	        if not fr:isKongcheng() then
		        return fr
		    end
	    end
	end
    --[[for _, tar in sgs.qlist(targets) do
	    if self:isFriend(tar) then
		    return tar
		end
	end]]
end

--¿ÕÕó
sgs.ai_skill_invoke.Y_kongzhen = function(self, data)
    local player = data:toPlayer()
	return self:isFriend(player)
end


--Â½¼¨
--»³éÙ
sgs.ai_skill_invoke.Y_huaiju = function(self, data)
    local move = data:toMoveOneTime()
    if move.from:getSeat()~=self.player:getSeat() then return true 
	elseif move.from:getSeat()==self.player:getSeat() then
	    if #self.friends_noself>0 then return true end
	end
	return false 
end

sgs.ai_skill_playerchosen.Y_huaiju= function(self, targets)
    self:sort(self.friends_noself,"defense")
    for _, fr in ipairs(self.friends_noself) do
	    if not (fr:hasSkill("kongcheng") and fr:isKongcheng()) and not fr:hasSkill("keji") then
		    return fr
		end
	end
end

--»ëÌì
sgs.ai_skill_use["@@Y_huntian"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local htcard
	local nextplayer = self.player:getNextAlive()
    self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
	    if (self.player:containsTrick("supply_shortage") and card:getSuit()==sgs.Card_Club) 
		or (self.player:containsTrick("indulgence") and card:getSuit()==sgs.Card_Heart) 
	    or (self.player:containsTrick("lightning") and not card:getSuit()==sgs.Card_Spade)  then
		    htcard = card break 
		end
	end
	if not htcard then
	    for _, acard in ipairs(cards) do
		    if self:isFriend(nextplayer) then
		        if (nextplayer:containsTrick("supply_shortage") and acard:getSuit()==sgs.Card_Club) 
		        or (nextplayer:containsTrick("indulgence") and acard:getSuit()==sgs.Card_Heart) 
		        or (nextplayer:containsTrick("lightning") and acard:getSuit()~=sgs.Card_Spade) then
				    htcard = acard break 
				end
			elseif self:isEnemy(nextplayer) then
		        if (nextplayer:containsTrick("lightning") and acard:getSuit()==sgs.Card_Spade) then
				    htcard = acard break 
				end
			end
		end
	end
	if not htcard then
	    for _, c in ipairs(cards) do
	        if c then htcard = c break end
		end 
	end
	return "#Y_huntiancard:"..htcard:getId()..":"
end

sgs.ai_skill_choice.Y_huntian = function(self,choices)
    local heart,spade,club,spade,notspade
	local peach = 0
    for _, c in sgs.qlist(self.player:getCards("h")) do
	    if c:getSuit()==sgs.Card_Heart then
		    heart=true
		elseif c:getSuit()==sgs.Card_Spade then
		    spade=true
		elseif c:getSuit()==sgs.Card_Club then
		    club=true
		end
		if c:getSuit()~=sgs.Card_Spade then
		    notspade=true
		elseif c:getSuit()==sgs.Card_Spade then
		    spade=true
		end
		if c:isKingOf("Peach") then 
		    peach = peach + 1
		end
	end
	local nextplayer = self.player:getNextAlive()
    if (self.player:containsTrick("supply_shortage") and club==true) 
	or (self.player:containsTrick("indulgence") and heart==true) 
	or (self.player:containsTrick("lightning") and notspade==true) then
		return "1"
    elseif self.player:getHandcardNum()==peach then
	    if self.player:isWounded() then
		    return "2"
	    elseif self:isFriend(nextplayer) and nextplayer:isWounded() and not nextplayer:containsTrick("supply_shortage") and not nextplayer:containsTrick("indulgence") then 
		    return "4"
		else 
		    return "2"
		end
	elseif self:isFriend(nextplayer) then
		if nextplayer:containsTrick("supply_shortage") then
			if club==true then 
				return "3" 
			else 
				return "5"
			end
		elseif nextplayer:containsTrick("indulgence") then
			if heart==true then
				return "3" 
			else 
				return "2"
			end
	    elseif nextplayer:containsTrick("lightning") then
			if notspade==true then 
				return "3" 
			else 
				return "5"
			end
		else
			return "5"
		end
	elseif self:isEnemy(nextplayer) then
		if nextplayer:containsTrick("lightning") then
			if spade==true then 
				return "3" 
			else 
				return "5"
			end
		else 
			return "4"
		end
    else 
		return "4"
    end		
end

sgs.ai_skill_invoke.Y_huntian2 = true

sgs.ai_skill_choice.Y_huntian2 = function(self,choices)
	for _, e in ipairs(self.enemies) do
	    if e:hasFlag("Y_huntian") then
	        return "htdiscard"
		end
	end
	return "htdraw"
end

--¶­°×
--Î´óÇ
sgs.ai_skill_invoke.Y_weiji = function(self, data)
    if self.player:getMaxHp()==1 then
	    if self:getCardsNum("Peach")>0 or self:getCardsNum("Analeptic")>0 then
		    return true
		end
	elseif self.player:getMaxHp()==2 then
	    if self.player:getHp()==2 then 
		    return true
		elseif self.player:getHp()==1 then
		    if self:getCardsNum("Peach")>0 or self:getCardsNum("Analeptic")>0 then
		        return true
			end
	    end
    elseif self.player:getMaxHp()>2 then
	    if self.player:getHp()==1 then 
	        return true
	    elseif self.player:getLostHp()>1 then
		    return true
	    elseif self.player:getLostHp()<1 then
	        if self:getCardsNum("Peach")>0 then
		        return true
			end
		elseif self.player:getLostHp()==1 then
	        if self.player:getHp()<3 then
		        return true
			end
		end
	end
	return false
end

--¾Æéä
function sgs.ai_cardsview.Y_jiushang(self, class_name, player)
	if class_name == "Analeptic" then
		if player:getMaxHp()>1 and player:getLostHp()>0 then
			return ("analeptic:Y_jiushang[no_suit:0]=.")
		end
	end
end

--Â½¿¹
--ÏàÏ§
Y_xiangxi_skill={}
Y_xiangxi_skill.name="Y_xiangxi"
table.insert(sgs.ai_skills,Y_xiangxi_skill)
Y_xiangxi_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("#Y_xiangxicard") then return end
	if #self.friends_noself<1 then return end
	local canxx = false
	for _,f in ipairs(self.friends_noself) do
		if f:containsTrick("supply_shortage") or f:containsTrick("indulgence") then
		    canxx = true break
		elseif f:getEquips():length()>0 then
		    if f:hasSkill("xiaoji") or f:hasSkill("xuanfeng") then
		        canxx = true break
		    elseif f:isWounded() and f:getArmor():objectName() == "silverlion" then
		        canxx = true break
			elseif self.player:getWeapon() and not f:getWeapon() then
			    canxx = true break
			end
		elseif f:getHandcardNum()>f:getHp() and f:getPhase()~=sgs.Player_NotActive and f:getHandcardNum()>=self.player:getHandcardNum() and not f:hasSkill("keji") then 
		    canxx = true break
		elseif f:getHandcardNum()<self.player:getHandcardNum() then
		    canxx = true break
		end
	end
	if canxx == true then 
	    return sgs.Card_Parse("#Y_xiangxicard:.:")
	end
end

sgs.ai_skill_use_func["#Y_xiangxicard"]=function(card,use,self)
	local target
	local tar1,tar2,tar3,tar4
	for _,f in ipairs(self.friends_noself) do
		if (f:containsTrick("supply_shortage") or f:containsTrick("indulgence")) and (self.player:getHandcardNum()-self.player:getHp()) < 2 then
		    tar1 = f 
		elseif f:getEquips():length()>0 then
		    if f:hasSkill("xiaoji") or f:hasSkill("xuanfeng") then
		        tar3 = f
		    elseif f:isWounded() and f:getArmor():objectName() == "silverlion" then
		        tar2 = f
			end
		elseif f:getHandcardNum()>f:getHp() and f:getPhase()~=sgs.Player_NotActive and f:getHandcardNum()>=self.player:getHandcardNum() and not f:hasSkill("keji") then 
		    tar2 = f
		elseif f:getHandcardNum()<self.player:getHandcardNum() then
		    tar4 = f
		end
	end
	if tar4 then target=tar4 end
	if tar3 then target=tar3 end
	if tar2 then target=tar3 end
	if tar1 then target=tar1 end
	if target then
	    use.card = card
	    if use.to then
		    use.to:append(target)
	    end
	    return
	end
end

sgs.ai_skill_choice.Y_xiangxi = function(self,choices)
    if self.player:containsTrick("supply_shortage") or self.player:containsTrick("indulgence") then
		return "j"
	elseif self.player:hasSkill("xiaoji") or self.player:hasSkill("xuanfeng") then
		return "e"
	elseif self.player:isWounded() and self.player:getArmor():objectName() == "silverlion" then
		return "e"
	else 
	   return "h"
    end
end

--¿Ë¹¹
sgs.ai_skill_invoke.Y_kegou = true
