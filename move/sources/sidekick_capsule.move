module supervlabs::sidekick_capsule {
    use apto_orm::orm_class;
    use apto_orm::orm_creator;
    use apto_orm::orm_module;
    use apto_orm::orm_object;
    use apto_orm::utilities;
    use aptos_framework::object::{Self, Object};
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::bcs;
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string;

    use supervlabs::badge;

    const CLASS_NAME: vector<u8> = b"SidekickCapsule";
    const ESIDEKICK_CAPSULE_OBJECT_NOT_FOUND: u64 = 1;
    const ENOT_SIDEKICK_CAPSULE_OBJECT: u64 = 2;
    const ESIDEKICK_CAPSULE_ALREADY_USED: u64 = 3;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct SidekickCapsule has key, drop {
        origin: string::String,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct UsedForSidekickCapsule has key, drop {
        object: address,
    }

    fun init_module(package: &signer) {
        let class_signer = orm_class::create_class_as_collection<SidekickCapsule>(
            package,
            string::utf8(b"SuperV Sidekick Capsules"),
            true, true, false, true, false, true, false,
            string::utf8(b"https://public.vir.supervlabs.io/virweb/nft/test_pet_tickets/collection.png"),
            string::utf8(b"The Sidekick Capsules Collection of Supervillain Idle RPG. By spending one Sidekick Capsule, you can randomly acquire one sidekick of varing grade. These sidekicks can be utilized in SuperVillain: Idle RPG."),
            0,
            true,
            true,
            @0x0,
            100,
            5,
        );
        orm_module::set<SidekickCapsule>(
            package,
            signer::address_of(package),
            signer::address_of(&class_signer),
        );
    }

    fun create_object(
        user: &signer,
        origin: string::String,
        name: string::String,
        badge_used: address,
        to: Option<address>,
    ): Object<SidekickCapsule>{
        let (orm_creator, orm_class) = orm_module::get<SidekickCapsule>(@supervlabs);
        let creator_signer = orm_creator::load_creator(user, orm_creator);
        let uri = string::utf8(b"https://public.vir.supervlabs.io/virweb/nft/test_pet_tickets/pet_ticket.png");
        let description = string::utf8(b"This is a capsule used to obtain Sidekicks from an on-chain random box. Sidekicks can be used in SuperVillain: Idle RPG, where they can be mounted by Villains to maximize the Villains' potential.");
        let ref = if (badge_used == @0x0) {
            let ref = token::create_named_token(
                &creator_signer,
                string::utf8(b"SuperV Sidekick Capsules"),
                description,
                utilities::join_str1(
                    &string::utf8(b"::"),
                    &origin,
                ),
                option::none(),
                uri,
            );
            let mutator_ref = token::generate_mutator_ref(&ref);
            token::set_name(&mutator_ref, name);
            ref
        } else {
            let badge_object = object::address_to_object<object::ObjectCore>(badge_used);
            let badge_signer = orm_object::load_signer(user, badge_object);
            assert!(
                !exists<UsedForSidekickCapsule>(badge_used),
                error::invalid_argument(ESIDEKICK_CAPSULE_ALREADY_USED),
            );
            move_to<UsedForSidekickCapsule>(&badge_signer, UsedForSidekickCapsule {
                object: badge_used
            });
            token::create(
                &creator_signer,
                string::utf8(b"SuperV Sidekick Capsules"),
                description,
                name,
                option::none(),
                uri,
            )
        };

        orm_object::init_properties(&ref,
            vector[
                string::utf8(b"badge_used"),
            ],
            vector[
                string::utf8(b"address"),
            ],
            vector[
                bcs::to_bytes<address>(&badge_used),
            ],
        );
        let object_signer = orm_object::init<SidekickCapsule>(&creator_signer, &ref, orm_class);
        move_to<SidekickCapsule>(&object_signer, SidekickCapsule {
            origin: origin
        });
        let obj = object::object_from_constructor_ref<SidekickCapsule>(&ref);
        if (badge_used != @0x0) {
            let (name, _, _) = badge::get(badge_used);
            orm_object::add_typed_property<SidekickCapsule, 0x1::string::String>(
                user, obj, string::utf8(b"origin"), name,
            );
        } else {
            orm_object::add_typed_property<SidekickCapsule, 0x1::string::String>(
                user, obj, string::utf8(b"origin"), origin,
            );
        };

        if (option::is_some(&to)) {
            let destination = option::extract<address>(&mut to);
            orm_object::transfer_initially(&ref, destination);
        };
        obj
    }

    fun update_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) {
        let object_address = object::object_address(&object);
        assert!(
            exists<SidekickCapsule>(object_address),
            error::invalid_argument(ENOT_SIDEKICK_CAPSULE_OBJECT),
        );
        let _object_signer = orm_object::load_signer(user, object);
    }

    public fun delete_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) acquires SidekickCapsule {
        let object_address = object::object_address(&object);
        assert!(
          exists<SidekickCapsule>(object_address),
          error::invalid_argument(ENOT_SIDEKICK_CAPSULE_OBJECT),
        );
        move_from<SidekickCapsule>(object_address);
        orm_object::remove(user, object);
    }

    entry fun create(
        user: &signer,
        origin: string::String,
        name: string::String,
        badge_used: address,
    ) {
        create_object(user, origin, name, badge_used, option::none());
    }

    entry fun create_to(
        user: &signer,
        origin: string::String,
        name: string::String,
        badge_used: address,
        to: address,
    ) {
        create_object(user, origin, name, badge_used, option::some(to));
    }

    entry fun update(
        user: &signer,
        object: address,
    ) {
        let obj = object::address_to_object<SidekickCapsule>(object);
        update_object(user, obj);
    }

    entry fun delete(
        user: &signer,
        object: address,
    ) acquires SidekickCapsule {
        let obj = object::address_to_object<SidekickCapsule>(object);
        delete_object(user, obj);
    }

    #[view]
    public fun get(object: address): (
        string::String,
        string::String,
        string::String,
        string::String,
        address,
    ) acquires SidekickCapsule {
        let o = object::address_to_object<SidekickCapsule>(object);
        let user_data = borrow_global<SidekickCapsule>(object);
        (
            user_data.origin,
            token::name(o),
            token::uri(o),
            token::description(o),
            property_map::read_address(&o, &string::utf8(b"badge_used")),
        )
    }

    #[view]
    public fun exists_at(object: address): bool {
        exists<SidekickCapsule>(object)
    }
}