run 'Long word' { 
	echo here_is_a_really_long_word.It_has_got_to_be_longer_than_1000_characters_for_the_lexical_analyzers_buffer_to_overflow_but_that_should_not_be_too_difficult_to_do.Let_me_start_writing_some_Lewis_Carroll.Twas_brillig_and_the_slithy_toves,Did_gyre_and_gimble_in_the_wabe.All_mimsy_were_the_borogoves,And_the_mome-raths_outgrabe.Beware_the_Jabberwock_my_son,The_jaws_that_bite,the_claws_that_catch.Beware_the_Jub-jub_bird,and_shun_The_frumious_Bandersnatch.He_took_his_vorpal_sword_in_hand,Long_time_the_manxome_foe_he_sought,So_rested_he_by_the_Tumtum_tree,And_stood_awhile_in_thought.And_as_in_uffish_thought_he_stood,The_Jabberwock,with_eyes_of_flame,Came_whiffling_through_the_tulgey_wood,And_burbled_as_it_came.One_two,one_two.And_through_and_through_The_vorpal_blade_went_snicker-snack.He_left_it_dead_and_with_its_head,He_went_galumphing_back.And_hast_thou_slain_the_Jabberwock.Come_to_my_arms,my_beamish_boy,Oh_frabjous_day.Callooh_callay.He_chortled_in_his_joy.Twas_brillig,and_the_slithy_toves,Did_gyre_and_gimble_in_the_wabe,All_mimsy_were_the_borogoves,And_the_mome-raths_outgrabe. > l1
	echo 'here_is_a_really_long_word.It_has_got_to_be_longer_than_1000_characters_for_the_lexical_analyzers_buffer_to_overflow_but_that_should_not_be_too_difficult_to_do.Let_me_start_writing_some_Lewis_Carroll.Twas_brillig_and_the_slithy_toves,Did_gyre_and_gimble_in_the_wabe.All_mimsy_were_the_borogoves,And_the_mome-raths_outgrabe.Beware_the_Jabberwock_my_son,The_jaws_that_bite,the_claws_that_catch.Beware_the_Jub-jub_bird,and_shun_The_frumious_Bandersnatch.He_took_his_vorpal_sword_in_hand,Long_time_the_manxome_foe_he_sought,So_rested_he_by_the_Tumtum_tree,And_stood_awhile_in_thought.And_as_in_uffish_thought_he_stood,The_Jabberwock,with_eyes_of_flame,Came_whiffling_through_the_tulgey_wood,And_burbled_as_it_came.One_two,one_two.And_through_and_through_The_vorpal_blade_went_snicker-snack.He_left_it_dead_and_with_its_head,He_went_galumphing_back.And_hast_thou_slain_the_Jabberwock.Come_to_my_arms,my_beamish_boy,Oh_frabjous_day.Callooh_callay.He_chortled_in_his_joy.Twas_brillig,and_the_slithy_toves,Did_gyre_and_gimble_in_the_wabe,All_mimsy_were_the_borogoves,And_the_mome-raths_outgrabe.' > l2
}
conds { cmp l1 l2 }

run 'Backslash-newline to space conversion' {
	echo -n h\
i
}
conds { match 'h i' }

run 'Backslash after variable terminates name' {
	echo -n $XS\\xs
}
conds { match $XS^\\xs }

run 'Backslash-newline after variable name space conversion' {
	echo -n $XS\
xs
}
conds { match $XS^' xs' }

run 'Backslash in middle of word' {
	echo -n h\\i
}
conds { match 'h\i' }

run 'Free-standing backslash' {
	echo -n h \\ i
}
conds { match 'h \ i' }

run 'EOF in comment' {
	$XS -c '# eof in comment'
}
conds { expect-success }

run 'Colon handled properly' {
	echo a:b
}
conds { match 'a:b' }

run 'Equals in middle of word is literal' {
	echo a=b
}
conds { match 'a=b' }

run 'Equals at end of word is literal' {
	echo c= d
}
conds { match 'c= d' }

run 'Equals at beginning of word is literal' {
	echo e =f
}
conds { match 'e =f' }

run 'Free-standing equals incorectly placed fails' {
	$XS -c 'echo g = h'
}
conds expect-failure

run 'Each across infix list' {
	each (1 2 3) { |x|
		echo -n $x
	}
}
conds {match 123}
