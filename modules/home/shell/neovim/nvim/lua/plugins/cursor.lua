-- 平滑光标：小范围移动用 smear，大跳交给 kitty 的 cursor_trail
-- Neovide 有自己的动画和 sonicboom，这里直接禁用避免叠加
return {
  {
    "sphamba/smear-cursor.nvim",
    enabled = not vim.g.neovide,
    event = "VeryLazy",
    opts = {
      -- 切 buffer / window 属于大跳，交给 kitty
      smear_between_buffers = false,
      smear_between_neighbor_lines = true,

      -- 比默认更跟手
      stiffness = 0.8,
      trailing_stiffness = 0.6,
      damping = 0.95,
      distance_stop_animating = 0.5,

      -- 近似 Neovide sonicboom 的粒子效果（常开）
      particles_enabled = true,
      never_draw_over_target = true,
      particles_per_second = 150,
      particle_max_num = 80,
      particle_max_lifetime = 350,
      particle_gravity = 10,
      min_distance_emit_particles = 0,
      particles_over_text = false,
    },
  },
}
