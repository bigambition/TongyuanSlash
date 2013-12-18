#ifndef _TONGYUAN_H
#define _TONGYUAN_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "structs.h"

class TongyuanPackage: public Package {
    Q_OBJECT

public:
    TongyuanPackage();
};

class TongganCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE TongganCard();
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class GongkuCard: public SkillCard {
    Q_OBJECT

public:
    Q_INVOKABLE GongkuCard();
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class FuchiCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE FuchiCard();
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
	
};

class QuanquanCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE QuanquanCard();	
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;

};

class XiaopangCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE XiaopangCard();

	virtual bool targetFixed() const;
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;

};

class HugangCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE HugangCard();	
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;

};  

class TuhaoCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE TuhaoCard();	
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;

};

class NvzongCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE NvzongCard();

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

class LaobanCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE LaobanCard();

	virtual void onUse(Room *room, const CardUseStruct &card_use) const;
};

class QiboCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE QiboCard();

	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class YuanzhuCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE YuanzhuCard();

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	//virtual void onUse(Room *room, const CardUseStruct &card_use) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

class FabuCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE FabuCard();

	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class DedaoCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE DedaoCard();
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class DashenCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE DashenCard();

	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JiaxinCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE JiaxinCard();
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JixiaoCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE JixiaoCard();
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class ShoujiCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE ShoujiCard();

	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
};

class BiaoyanCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE BiaoyanCard();
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class QianxuCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE QianxuCard();
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class XuanjiangCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE XuanjiangCard();

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

class ChuyiCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE ChuyiCard();

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;

	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

//class YouxiCard: public SkillCard {
//	Q_OBJECT
//
//public:
//	Q_INVOKABLE YouxiCard();
//
//	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
//	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
//};

class WendangCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE WendangCard();

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class ShoujiaoCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE ShoujiaoCard();
	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JiamiCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE JiamiCard();

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JiesongCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE JiesongCard();

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

class RenyiCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE RenyiCard();

	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class HuyouCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE HuyouCard();

	virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class BenzouCard: public SkillCard {
	Q_OBJECT

public:
	Q_INVOKABLE BenzouCard();

	virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
	virtual void onEffect(const CardEffectStruct &effect) const;
};

#endif