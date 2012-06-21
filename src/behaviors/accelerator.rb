define_behavior :accelerator do
  requires :director
  setup do
    actor.has_attributes speed: opts[:speed],
                         accel: vec2(0,0),
                         max_speed: opts[:max_speed],
                         vel: vec2(0,0),
                         max_jump_force: 400,
                         jumping_force: 0,
                         flip_h: false
                        
    director.when :update do |time, time_secs|
      # TODO performance of creating vecs here instead of modifying in place?
      if actor.move_right?
        actor.accel += vec2(actor.speed * time_secs, 0)
        actor.flip_h = false
      elsif actor.move_left?
        actor.flip_h = true
        actor.accel += vec2(-actor.speed * time_secs, 0)
      end

      # TODO should jumping be its own behavior?
      if actor.attempt_jump? && actor.on_ground
        actor.jumping_force = actor.max_jump_force
      end

      unless (0-actor.jumping_force).abs <= 0.001
        actor.accel.y -= actor.jumping_force * time_secs
        max = actor.max_jump_force
        jf = actor.jumping_force
        actor.jumping_force -= 9.0 * jf / max * time
      end

      actor.when :hit_top do
        actor.jumping_force = 0
      end

      actor.vel += actor.accel

      if (0.0-actor.vel[1]).abs <= 0.1 && actor.action != :idle
        actor.action = :idle
      end
      
      if (actor.vel[0]) > 0.01
        actor.action = :walking_right unless actor.action == :walking_right
      elsif (actor.vel[0]) < -0.01
        actor.action = :walking_left unless actor.action == :walking_left
      end
      
      if actor.vel[1] < 0.05
        actor.action = :jumping unless actor.action == :jumping
      elsif actor.vel[1] > 0.1 && !actor.on_ground
        actor.action = :falling unless actor.action == :falling
      end
      actor.vel.magnitude = actor.max_speed if actor.vel.magnitude > actor.max_speed
      # XXX how do I do this in the correct order?
      actor.on_ground = false
      # EEK.. TODO XXX where should this live?
      actor.accel = vec2(0,0)

    end

    actor.when :remove_me do
      director.unsubscribe_all self
    end
  end

  helpers do
    include MinMaxHelpers
  end
end
