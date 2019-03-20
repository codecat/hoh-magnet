namespace Modifiers
{
	class PickupMagnet : Modifier
	{
		int m_time;
		int m_timeC;
		int m_radius;
		float m_speed;

		array<Pickup@> m_pickups;

		PickupMagnet() {}
		PickupMagnet(UnitPtr unit, SValue& params)
		{
			m_timeC = m_time = GetParamInt(unit, params, "time", false, 300);
			m_radius = GetParamInt(unit, params, "radius", false, 40);
			m_speed = GetParamFloat(unit, params, "speed", false, 5.0f);
		}

		Modifier@ Instance() override
		{
			auto ret = PickupMagnet();
			ret = this;
			ret.m_cloned++;
			return ret;
		}

		bool HasUpdate() override { return true; }
		void Update(PlayerBase@ player, int dt) override
		{
			vec2 playerPos = xy(player.m_unit.GetPosition());

			for (uint i = 0; i < m_pickups.length(); i++)
			{
				auto pickup = m_pickups[i];
				if (!pickup.m_visible)
					continue;

				auto body = pickup.m_unit.GetPhysicsBody();
				if (body is null)
					continue;

				vec2 pickupPos = xy(pickup.m_unit.GetPosition());
				vec2 dir = normalize(playerPos - pickupPos);

				float d = dist(playerPos, pickupPos);
				float ds = max(0.2f, 1.0f - (d / float(m_radius)));

				body.SetStatic(false);
				body.SetLinearVelocity(dir * (m_speed * ds));
			}

			m_timeC -= dt;
			if (m_timeC > 0)
				return;

			m_timeC = m_time;

			array<Pickup@> previousPickups = m_pickups;
			m_pickups.removeRange(0, m_pickups.length());

			auto arrUnits = g_scene.QueryCircle(playerPos, m_radius, ~0, RaycastType::Any, true);
			for (uint i = 0; i < arrUnits.length(); i++)
			{
				auto pickup = cast<Pickup>(arrUnits[i].GetScriptBehavior());
				if (pickup is null || !pickup.m_visible)
					continue;

				if (!CanApplyEffects(pickup.m_effects, null, player.m_unit, xy(pickup.m_unit.GetPosition()), vec2(), 1.0f, pickup.m_effectsIgnore))
					continue;

				vec2 pickupPos = xy(pickup.m_unit.GetPosition());

				bool canReach = true;
				auto arrResult = g_scene.Raycast(playerPos, pickupPos, ~0, RaycastType::Shot);
				for (uint i = 0; i < arrResult.length(); i++)
				{
					auto unit = arrResult[i].FetchUnit(g_scene);
					if (unit.GetScriptBehavior() is null)
					{
						canReach = false;
						break;
					}
				}

				if (canReach)
				{
					m_pickups.insertLast(pickup);

					int previousIndex = previousPickups.findByRef(pickup);
					if (previousIndex != -1)
						previousPickups.removeAt(previousIndex);
				}
			}

			for (uint i = 0; i < previousPickups.length(); i++)
			{
				auto pickup = previousPickups[i];
				auto body = pickup.m_unit.GetPhysicsBody();
				if (body !is null)
					body.SetStatic(true);
			}
		}
	}
}
