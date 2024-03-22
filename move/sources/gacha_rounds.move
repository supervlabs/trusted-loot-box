module supervlabs::gacha_rounds {
    use aptos_framework::timestamp;
    use std::vector;
    use std::signer;
    use std::error;
    use std::string;
    use aptos_framework::object;

    const EGACHA_ROUNDS_NOT_FOUND: u64 = 1;
    const EGACHA_ROUNDS_NOT_CONFIGURED: u64 = 2;
    const EINVALID_PSEUDO_RANDOM_RANGE: u64 = 3;
    const ENOT_AUTHORIZED_OPERATION: u64 = 4;
    const EGACHA_ROUND_LOG_NOT_FOUND: u64 = 5;
    const EPAST_GACHA_ROUND_NOT_DELETED: u64 = 6;

    const GRADE_COMMON: vector<u8> = b"common"; // common must not be used
    const GRADE_UNCOMMON: vector<u8> = b"uncommon"; // 0th index
    const GRADE_RARE: vector<u8> = b"rare"; // 1st index
    const GRADE_EPIC: vector<u8> = b"epic"; // 2nd index
    const GRADE_LEGENDARY: vector<u8> = b"legendary"; // 3rd index

    struct GachaDropRate has copy, drop, store {
        grade: string::String,
        numerator: u64,
    }

    struct GachaRound has copy, drop, store {
        numerators: vector<GachaDropRate>,
        denominator: u64,
        updated_at: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct GachaRounds has key, drop {
        creator: address,
        current_round: u64,
        rounds: vector<GachaRound>,
        updated_at: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /** It is used to record the current round of the gacha item */
    struct GachaRoundLog has key, drop {
        current_round: u64,
        selected_round: u64,
        updated_at: u64,
    }

    inline fun get_current_round(round_obj: address): (&GachaRound, u64) acquires GachaRounds {
        assert!(exists<GachaRounds>(round_obj), error::not_found(EGACHA_ROUNDS_NOT_FOUND));
        let gr = borrow_global<GachaRounds>(round_obj);
        let len = vector::length(&gr.rounds);
        assert!(len > 0, error::not_found(EGACHA_ROUNDS_NOT_CONFIGURED));
        let target_round = gr.current_round;
        if (target_round >= len) {
            target_round = len - 1;
        };
        (vector::borrow(&gr.rounds, target_round), gr.current_round)
    }

    inline fun get_round(round_obj: address, target_round: u64): &GachaRound acquires GachaRounds {
        assert!(exists<GachaRounds>(round_obj), error::not_found(EGACHA_ROUNDS_NOT_FOUND));
        let gr = borrow_global<GachaRounds>(round_obj);
        vector::borrow(&gr.rounds, target_round)
    }

    public fun load_drop_rates(round_obj: address): (u64, vector<u64>, u64) acquires GachaRounds {
        let (round, current_round) = get_current_round(round_obj);
        let len = vector::length<GachaDropRate>(&round.numerators);
        assert!(len > 0, error::not_found(EGACHA_ROUNDS_NOT_CONFIGURED));

        let numerators: vector<u64> = vector[];
        vector::for_each_ref(&round.numerators, |e| {
            let drop_rate: &GachaDropRate = e;
            vector::push_back(&mut numerators, drop_rate.numerator);
        });
        (current_round, numerators, round.denominator)
    }

    #[view]
    // load_drop_rates_4 returns [uncommon, rare, epic, legendary, mythic, denominator]
    public fun load_drop_rates_5(round_obj: address): (u64, u64, u64, u64, u64, u64, u64) acquires GachaRounds {
        use std::vector::borrow;
        let (cround, numerators, denominator) = load_drop_rates(round_obj);
        let len = vector::length(&numerators);
        if (len == 1) return (cround, *borrow(&numerators, 0), 0, 0, 0, 0, denominator);
        if (len == 2) return (cround, *borrow(&numerators, 0), *borrow(&numerators, 1), 0, 0, 0, denominator);
        if (len == 3) return (cround, *borrow(&numerators, 0), *borrow(&numerators, 1), *borrow(&numerators, 2), 0, 0, denominator);
        if (len == 4) return (cround, *borrow(&numerators, 0), *borrow(&numerators, 1), *borrow(&numerators, 2), *borrow(&numerators, 3), 0, denominator);
        (cround, *borrow(&numerators, 0), *borrow(&numerators, 1), *borrow(&numerators, 2), *borrow(&numerators, 3), *borrow(&numerators, 4), denominator)
    }

    #[view]
    // load_drop_rates_4 returns [uncommon, rare, epic, legendary, denominator]
    public fun load_drop_rates_4(round_obj: address): (u64, u64, u64, u64, u64, u64) acquires GachaRounds {
        let (cround, n1, n2, n3, n4, _, denominator) = load_drop_rates_5(round_obj);
        (cround, n1, n2, n3, n4, denominator)
    }

    public fun round_up(creator: &signer, round_obj: address) acquires GachaRounds {
        assert!(exists<GachaRounds>(round_obj), error::not_found(EGACHA_ROUNDS_NOT_FOUND));
        let gr = borrow_global_mut<GachaRounds>(round_obj);
        assert!(gr.creator == signer::address_of(creator),
            error::invalid_argument(ENOT_AUTHORIZED_OPERATION));
        gr.current_round = gr.current_round + 1;
    }

    public fun add(
        round_obj: &signer,
        creator: address,
        grades: vector<string::String>,
        numerators: vector<u64>,
        denominator: u64,
    ): u64 acquires GachaRounds {
        let obj_address = signer::address_of(round_obj);
        let updated_at = timestamp::now_microseconds();
        let round: GachaRound = GachaRound {
            numerators: vector[],
            denominator,
            updated_at,
        };
        let i = 0;
        let len = vector::length(&grades);
        while (i < len) {
            let drop_rate = GachaDropRate {
                grade: *vector::borrow(&grades, i),
                numerator: *vector::borrow(&numerators, i),
            };
            vector::push_back(&mut round.numerators, drop_rate);
            i = i + 1;
        };

        if (exists<GachaRounds>(obj_address)) {
            let grs = borrow_global_mut<GachaRounds>(obj_address);
            vector::push_back(&mut grs.rounds, round);
            return grs.current_round
        } else {
            move_to<GachaRounds>(round_obj, GachaRounds {
                creator, current_round: 0, updated_at,
                rounds: vector[ round ],
            });
            return 0
        }
    }

    public fun delete(round_obj: &signer, target_round: u64) acquires GachaRounds {
        let obj_address = signer::address_of(round_obj);
        assert!(
            exists<GachaRounds>(obj_address),
            error::not_found(EGACHA_ROUNDS_NOT_FOUND)
        );
        let grs = borrow_global_mut<GachaRounds>(obj_address);
        assert!(
            target_round > grs.current_round, 
            error::not_found(EPAST_GACHA_ROUND_NOT_DELETED)
        );
        assert!(
            target_round < vector::length(&grs.rounds), 
            error::not_found(EPAST_GACHA_ROUND_NOT_DELETED)
        );
        vector::remove(&mut grs.rounds, target_round);
    }

    public fun set_round_log(round_obj: address, target_ref: &object::ConstructorRef, current_round: u64) acquires GachaRounds {
        assert!(exists<GachaRounds>(round_obj), error::not_found(EGACHA_ROUNDS_NOT_FOUND));
        let gr = borrow_global<GachaRounds>(round_obj);
        let len = vector::length(&gr.rounds);
        assert!(len > 0, error::not_found(EGACHA_ROUNDS_NOT_CONFIGURED));
        let target_round = current_round;
        if (target_round >= len) {
            target_round = len - 1;
        };
        let obj_signer = object::generate_signer(target_ref);
        move_to<GachaRoundLog>(&obj_signer, GachaRoundLog {
            current_round, selected_round: target_round, updated_at: timestamp::now_microseconds(), 
        });
    }

    #[view]
    public fun get_round_log_with_drop_rates(round_obj: address, target_obj: address): (
        u64, u64, vector<u64>, u64, u64
    ) acquires GachaRounds, GachaRoundLog {
        assert!(exists<GachaRoundLog>(target_obj), error::not_found(EGACHA_ROUND_LOG_NOT_FOUND));
        let log = borrow_global<GachaRoundLog>(target_obj);
        let round = get_round(round_obj, log.selected_round);
        let numerators: vector<u64> = vector[];
        vector::for_each_ref(&round.numerators, |e| {
            let drop_rate: &GachaDropRate = e;
            vector::push_back(&mut numerators, drop_rate.numerator);
        });
        (log.current_round, log.selected_round, numerators, round.denominator, log.updated_at)
    }
}