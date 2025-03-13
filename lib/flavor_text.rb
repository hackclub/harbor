class FlavorText
  def self.same_user
    [
      "it u!",
      "hey there",
      "look familiar?",
      "i'm seeing double!!",
      "you again?",
      "your twin?!",
      "despite everything, it's still you"
    ]
  end

  def self.loading_messages
    [
      "Generating leaderboard...",
      "Crunching the numbers...",
      "Hold tight, I'm working on it...",
      "chugging the data juice",
      "chugging *Stat-Cola©*, for those who want to know things™",
      "that's numberwang!",
      "crunching the numbers",
      "munching the numbers",
      "gurgling the bits",
      "juggling the electrons",
      "chomping the bytes",
      "playing the photons on bass",
      "reticulating the splines",
      "rolling down data hills",
      "frolicking through fields of numbers",
      "skiing the data slopes",
      "dropping in and sending it",
      "zooming through the cyber-pipes",
      "grabbing the stats",
      "switching the dependent and independent variables",
      "flipping a coin to choose which axis to use",
      "warming up the powerhouse of the cell",
      "calculating significant figures...",
      "calculating insignificant figures...",
      "p-hacking the n value",
      "computing P = NP",
      "realizing P ≠ NP",
      "so, uh... come here often?",
      "*powertool noises*",
      "*frantic typing noises*",
      "*keyboard clacking noises*",
      "*crunching number noises*",
      "*beep* *beep* *beep*",
      "carrying the one",
      "team-carrying the one",
      "carrying the zero",
      "ganking the one before it gets carried",
      "spinning violently around the y-axis",
      "#{%w[tokenizing serializing stringifying].sample} #{[ "blood, sweat, & tears", "the human condition", "personal experiences", "elbow grease" ].sample}",
      "waking up the bits",
      "petting the bits",
      "testing patience",
      "[npm] now installing #{rand(3..7)} of #{rand(26_000..29_000)} packages",
      "spinning the rgbs",
      "Installing dependencies",
      "shoveling the overflowed pixels",
      ".split() === :large_blue_circle::large_green_circle::large_yellow_circle::large_orange_circle::red_circle::large_purple_circle:",
      "Are ya' winning, son?",
      "Dropkicking the cache into the sun",
      "[#{self.other_servers.sample}] starting on port #{self.common_ports.sample}",
      "compressing the accountants"
    ]
  end

  def self.common_ports
    %w[
      80
      443
      3000
      3001
      3002
    ]
  end

  def self.other_servers
    %w[
      express
      django
      flask
      ngrok
      nextjs
    ]
  end

  def self.other_languages
    %w[
      bash
      bunjs
      c
      c#
      c++
      go
      java
      javascript
      kotlin
      perl
      php
      python
      rust
      swift
    ]
  end

  def self.rare_loading_messages
    [
      "I would like to thank the academy...",
      "If you really think about it, isn't coffee just refried bean water?",
      "I'd be faster if I was written in #{self.other_languages.sample}",
      "Loading better loading messages..."
    ]
  end

  def self.compliment
    [
      "You're doing great!",
      "You're a star!",
      "Keep it up!",
      "No stopping you!"

    ]
  end

  def self.rare_compliment
    [ "Don't let your dreams be memes!" ]
  end

  def self.random_time_video
    # these are just random videos/memes on youtube that have time in the title.
    # your milage may vary.
    [
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/d20a0673d3816509809ec028d02907c28c7926f7_it_s_pizza_time_at_new_years__lug5nf47wr4_.mp4",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/5836f8e156b985df9399467b1d2c642d2e2b7d48_dog_jumping_off_a_cliff_to_work_this_time_by_king_gizzard_and_the_lizard_wizard__2sp8-g61kpi_.mp4",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/8314bea9ee0a03e692ff7d52a68aa55880bebd75_it_s_time_to_kick_gum__gnvag2nwaug_.webm",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/85aa18933d81e3858caa3af5223fa7a651e9916f_this_time_he_can_sit_in_the_canoe_for_up_to_an_hour.__spc_2dxjbnw_.webm",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/ee015eb5e8a0bc58b9ded2d2aba57c55131c490a____cantina_theme____played_by_a_pencil_and_a_girl_with_too_much_time_on_her_hands__jcghl0lbdsk_.mp4",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/19f83326fae797d45aaf0ea58d7ed656704a2796_man_takes_a_photo_of_himself_30_times_a_second_every_second_for_12_seconds__gqgqjcijcty_.webm",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/7230a977c72609e88d38bc75ae293a5c217f520b_it_s_hamtaro_time__7hpp7pullwg_.webm",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/5108691fcfe1ae6939849e01f4474a1d55e9ee77_the_best_chess_handshake_of_all_time__chessbaseindia__tif2vt8s8p8_.webm",
      "https://www.youtube.com/watch?v=lMUSyvTBokc",
      "https://www.youtube.com/watch?v=wH4QsKQPYKQ&t=30s",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/125740ef06dac1b3a32d9d2c453d8c81bddd7fdb_stop-measuring-time-v0-1n64qvw0xfpa1.webp",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/1112c1e28e3a017738d1c4db1a18e292651fc49d_ey3jskc8brp11.webp",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/0bea6b9ea2f2d1a4a2bcb34f4763c390ea5d7672_1fagap51epelkfjtbs0ioh0ax116ed5_djuufhyvpie.webp",
      "https://hc-cdn.hel1.your-objectstorage.com/s/v3/b35fd20790ab01c9f8400efaf454a21337a7f51e_8o4i3olrnqpy.webp"
    ]
  end

  def self.motto
    [
      "track your time before it tracks you!",
      "it's the thought that counts",
      "git #{%w[good gud].sample}",
      "time flies when you git good!",
      "take your time!",
      "have your time and eat it too!",
      "give it some time!",
      "it's time to tiempo!",
      "take your time... or we will!",
      "have your time and eat it too!",
      "give it some time!",
      "take a time, leave a time!",
      "the only thing that can't be bought!"
    ]
  end
end
