#include "tongyuandream.h"
#include "client.h"
#include "engine.h"
#include "general.h"
#include "room.h"

//Í¬ÔªÃÎ
Dream::Dream(Suit suit, int number)
	: SingleTargetTrick(suit, number)
{
	setObjectName("dream");
}

bool Dream::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
	int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
	return targets.length() < total_num && to_select != Self;
}

void Dream::onEffect(const CardEffectStruct &effect) const{
	if(effect.from->isAlive())
		effect.from->drawCards(2);
	if(effect.to->isAlive())
		effect.to->drawCards(2);
}

TongyuanDreamPackage::TongyuanDreamPackage()
	: Package("tongyuandream", Package::CardPack)
{
	QList<Card *> cards;

	// spade
	//cards << new Dream(Card::Spade, 1)
	//	<< new Vine(Card::Spade, 2)
	//	<< new Analeptic(Card::Spade, 3)
	//	<< new ThunderSlash(Card::Spade, 4)
	//	<< new ThunderSlash(Card::Spade, 5)
	//	<< new ThunderSlash(Card::Spade, 6)
	//	<< new ThunderSlash(Card::Spade, 7)
	//	<< new ThunderSlash(Card::Spade, 8)
	//	<< new Analeptic(Card::Spade, 9)
	//	<< new SupplyShortage(Card::Spade, 10)
	//	<< new IronChain(Card::Spade, 11)
	//	<< new IronChain(Card::Spade, 12)
	//	<< new Nullification(Card::Spade, 13);
	//// club
	//cards << new SilverLion(Card::Club, 1)
	//	<< new Vine(Card::Club, 2)
	//	<< new Analeptic(Card::Club, 3)
	//	<< new SupplyShortage(Card::Club, 4)
	//	<< new ThunderSlash(Card::Club, 5)
	//	<< new ThunderSlash(Card::Club, 6)
	//	<< new ThunderSlash(Card::Club, 7)
	//	<< new ThunderSlash(Card::Club, 8)
	//	<< new Analeptic(Card::Club, 9)
	//	<< new IronChain(Card::Club, 10)
	//	<< new IronChain(Card::Club, 11)
	//	<< new IronChain(Card::Club, 12)
	//	<< new IronChain(Card::Club, 13);

	//// heart
	cards << new Dream(Card::Heart, 9);
	//	<< new FireAttack(Card::Heart, 2)
	//	<< new FireAttack(Card::Heart, 3)
	//	<< new FireSlash(Card::Heart, 4)
	//	<< new Peach(Card::Heart, 5)
	//	<< new Peach(Card::Heart, 6)
	//	<< new FireSlash(Card::Heart, 7)
	//	<< new Jink(Card::Heart, 8)
	//	<< new Jink(Card::Heart, 9)
	//	<< new FireSlash(Card::Heart, 10)
	//	<< new Jink(Card::Heart, 11)
	//	<< new Jink(Card::Heart, 12)
	//	<< new Nullification(Card::Heart, 13);

	//// diamond
	//cards << new Fan(Card::Diamond, 1)
	//	<< new Peach(Card::Diamond, 2)
	//	<< new Peach(Card::Diamond, 3)
	//	<< new FireSlash(Card::Diamond, 4)
	//	<< new FireSlash(Card::Diamond, 5)
	//	<< new Jink(Card::Diamond, 6)
	//	<< new Jink(Card::Diamond, 7)
	//	<< new Jink(Card::Diamond, 8)
	//	<< new Analeptic(Card::Diamond, 9)
	//	<< new Jink(Card::Diamond, 10)
	//	<< new Jink(Card::Diamond, 11)
	//	<< new FireAttack(Card::Diamond, 12);

	//DefensiveHorse *hualiu = new DefensiveHorse(Card::Diamond, 13);
	//hualiu->setObjectName("HuaLiu");

	/*cards << hualiu;*/

	foreach (Card *card, cards)
		card->setParent(this);

	/*skills << new GudingBladeSkill << new FanSkill
		<< new VineSkill << new SilverLionSkill;*/
}

ADD_PACKAGE(TongyuanDream)
