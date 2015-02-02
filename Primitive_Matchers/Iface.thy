theory Iface
imports String "../Output_Format/Negation_Type"
begin

section{*Network Interfaces*}


datatype iface = Iface "string negation_type"

definition IfaceAny :: iface where
  "IfaceAny \<equiv> Iface (Pos ''+'')"
definition IfaceFalse :: iface where
  "IfaceFalse \<equiv> Iface (Neg ''+'')"

text_raw{*If the interface name ends in a ``+'', then any interface which begins with this name will match. (man iptables)

Here is how iptables handles this wildcard on my system. A packet for the loopback interface \texttt{lo} is matched by the following expressions
\begin{itemize}
  \item lo
  \item lo+
  \item l+
  \item +
\end{itemize}

It is not matched by the following expressions
\begin{itemize}
  \item lo++
  \item lo+++
  \item lo1+
  \item lo1
\end{itemize}

By the way: \texttt{Warning: weird characters in interface ` ' ('/' and ' ' are not allowed by the kernel).}
*}


  
subsection{*Helpers for the interface name (@{typ string})*}
  (*Do not use outside this thy! Type is really misleading.*)
  text{*
    argument 1: interface as in firewall rule - Wildcard support
    argument 2: interface a packet came from - No wildcard support*}
  fun internal_iface_name_match :: "string \<Rightarrow> string \<Rightarrow> bool" where
    "internal_iface_name_match []     []         \<longleftrightarrow> True" |
    "internal_iface_name_match (i#is) []         \<longleftrightarrow> (i = CHR ''+'' \<and> is = [])" |
    "internal_iface_name_match []     (_#_)      \<longleftrightarrow> False" |
    "internal_iface_name_match (i#is) (p_i#p_is) \<longleftrightarrow> (if (i = CHR ''+'' \<and> is = []) then True else (
          (p_i = i) \<and> internal_iface_name_match is p_is
    ))"
  
  (*<*)
  --"Examples"
    lemma "internal_iface_name_match ''lo'' ''lo''" by eval
    lemma "internal_iface_name_match ''lo+'' ''lo''" by eval
    lemma "internal_iface_name_match ''l+'' ''lo''" by eval
    lemma "internal_iface_name_match ''+'' ''lo''" by eval
    lemma "\<not> internal_iface_name_match ''lo++'' ''lo''" by eval
    lemma "\<not> internal_iface_name_match ''lo+++'' ''lo''" by eval
    lemma "\<not> internal_iface_name_match ''lo1+'' ''lo''" by eval
    lemma "\<not> internal_iface_name_match ''lo1'' ''lo''" by eval
    text{*The wildcard interface name*}
    lemma "internal_iface_name_match ''+'' ''''" by eval (*>*)


  fun iface_name_is_wildcard :: "string \<Rightarrow> bool" where
    "iface_name_is_wildcard [] \<longleftrightarrow> False" |
    "iface_name_is_wildcard [s] \<longleftrightarrow> s = CHR ''+''" |
    "iface_name_is_wildcard (_#ss) \<longleftrightarrow> iface_name_is_wildcard ss"
  lemma iface_name_is_wildcard_alt: "iface_name_is_wildcard eth \<longleftrightarrow> eth \<noteq> [] \<and> last eth = CHR ''+''"
    apply(induction eth rule: iface_name_is_wildcard.induct)
      apply(simp_all)
    done
  lemma iface_name_is_wildcard_alt': "iface_name_is_wildcard eth \<longleftrightarrow> eth \<noteq> [] \<and> hd (rev eth) = CHR ''+''"
    apply(simp add: iface_name_is_wildcard_alt)
    using hd_rev by fastforce
  lemma iface_name_is_wildcard_fst: "iface_name_is_wildcard (i # is) \<Longrightarrow> is \<noteq> [] \<Longrightarrow> iface_name_is_wildcard is"
    by(simp add: iface_name_is_wildcard_alt)

subsection{*Matching*}
  fun match_iface :: "iface \<Rightarrow> string \<Rightarrow> bool" where
    "match_iface (Iface (Pos i)) p_iface \<longleftrightarrow> internal_iface_name_match i p_iface" |
    "match_iface (Iface (Neg i)) p_iface \<longleftrightarrow> \<not> internal_iface_name_match i p_iface"
  
  --"Examples"
    lemma "  match_iface (Iface (Pos ''lo''))    ''lo''"
          "  match_iface (Iface (Pos ''lo+''))   ''lo''"
          "  match_iface (Iface (Pos ''l+''))    ''lo''"
          "  match_iface (Iface (Pos ''+''))     ''lo''"
          "\<not> match_iface (Iface (Pos ''lo++''))  ''lo''"
          "\<not> match_iface (Iface (Pos ''lo+++'')) ''lo''"
          "\<not> match_iface (Iface (Pos ''lo1+''))  ''lo''"
          "\<not> match_iface (Iface (Pos ''lo1''))   ''lo''"
          "  match_iface (Iface (Pos ''+''))     ''eth0''"
          "\<not> match_iface (Iface (Neg ''+''))     ''eth0''"
          "\<not> match_iface (Iface (Neg ''eth+''))  ''eth0''"
          "  match_iface (Iface (Neg ''lo+''))   ''eth0''"
          "\<not> match_iface (Iface (Neg ''lo+''))   ''loX''"
          "\<not> match_iface (Iface (Pos ''''))      ''loX''"
          "  match_iface (Iface (Neg ''''))      ''loX''"
          "\<not> match_iface (Iface (Pos ''foobar+''))     ''foo''" by eval+

  lemma match_IfaceAny: "match_iface IfaceAny i"
    by(cases i, simp_all add: IfaceAny_def)
  lemma match_IfaceFalse: "\<not> match_iface IfaceFalse i"
    by(cases i, simp_all add: IfaceFalse_def)


  --{*@{const match_iface} explained by the individual cases*}
  lemma match_iface_case_pos_nowildcard: "\<not> iface_name_is_wildcard i \<Longrightarrow> match_iface (Iface (Pos i)) p_i \<longleftrightarrow> i = p_i"
    apply(simp)
    apply(induction i p_i rule: internal_iface_name_match.induct)
       apply(auto simp add: iface_name_is_wildcard_alt split: split_if_asm)
    done
  lemma match_iface_case_neg_nowildcard: "\<not> iface_name_is_wildcard i \<Longrightarrow> match_iface (Iface (Neg i)) p_i \<longleftrightarrow> i \<noteq> p_i"
    apply(simp)
    apply(induction i p_i rule: internal_iface_name_match.induct)
       apply(auto simp add: iface_name_is_wildcard_alt split: split_if_asm)
    done
  lemma match_iface_case_pos_wildcard_prefix:
    "iface_name_is_wildcard i \<Longrightarrow> match_iface (Iface (Pos i)) p_i \<longleftrightarrow> butlast i = take (length i - 1) p_i"
    apply(simp)
    apply(induction i p_i rule: internal_iface_name_match.induct)
       apply(simp_all)
     apply(simp add: iface_name_is_wildcard_alt split: split_if_asm)
    apply(intro conjI)
     apply(simp add: iface_name_is_wildcard_alt split: split_if_asm)
    apply(intro impI)
    apply(simp add: iface_name_is_wildcard_fst)
    by (metis One_nat_def length_0_conv list.sel(1) list.sel(3) take_Cons')
  lemma match_iface_case_pos_wildcard_length: "iface_name_is_wildcard i \<Longrightarrow> match_iface (Iface (Pos i)) p_i \<Longrightarrow> length p_i \<ge> (length i - 1)"
    apply(simp)
    apply(induction i p_i rule: internal_iface_name_match.induct)
       apply(simp_all)
     apply(simp add: iface_name_is_wildcard_alt split: split_if_asm)
    done
  corollary match_iface_case_pos_wildcard:
    "iface_name_is_wildcard i \<Longrightarrow> match_iface (Iface (Pos i)) p_i \<longleftrightarrow> butlast i = take (length i - 1) p_i \<and> length p_i \<ge> (length i - 1)"
    using match_iface_case_pos_wildcard_length match_iface_case_pos_wildcard_prefix by blast
  lemma match_iface_case_neg_wildcard_prefix: "iface_name_is_wildcard i \<Longrightarrow> match_iface (Iface (Neg i)) p_i \<longleftrightarrow> butlast i \<noteq> take (length i - 1) p_i"
    apply(simp)
    apply(induction i p_i rule: internal_iface_name_match.induct)
       apply(simp_all)
     apply(simp add: iface_name_is_wildcard_alt split: split_if_asm)
    apply(intro conjI)
     apply(simp add: iface_name_is_wildcard_alt split: split_if_asm)
    apply(simp add: iface_name_is_wildcard_fst)
    by (metis One_nat_def length_0_conv list.sel(1) list.sel(3) take_Cons')
  (* TODO: match_iface_case_neg_wildcard_length? hmm, p_i can be shorter or longer, essentially different*)

  text{*
  If the interfaces are no wildcards, they must be equal, otherwise None
  If one is a wildcard, the other one must `match'
  If both are wildcards: Longest prefix of both
  *}
  fun most_specific_iface :: "iface \<Rightarrow> iface \<Rightarrow> iface option" where
    "most_specific_iface (Iface (Pos i1)) (Iface (Pos i2)) = (case (iface_name_is_wildcard i1, iface_name_is_wildcard i2) of
      (True,  True) \<Rightarrow> None  |
      (True,  False) \<Rightarrow> None |
      (False, True) \<Rightarrow> None |
      (False, False) \<Rightarrow> None)"
  (*TODO: merging Pos and Neg Iface!! ? ? Requires returning a list?*)

(* Old stuff below *)
    (*TODO TODO TODO: a packet has a fixed string as interface, there is no wildcard in it! TODO*)
    (*TODO: this must be redone! see below*)

fun iface_name_eq :: "string \<Rightarrow> string \<Rightarrow> bool" where
  "iface_name_eq [] [] \<longleftrightarrow> True" |
  "iface_name_eq [i1] [] \<longleftrightarrow> (i1 = CHR ''+'')" |
  "iface_name_eq [] [i2] \<longleftrightarrow> (i2 = CHR ''+'')" |
  "iface_name_eq [i1] [i2] \<longleftrightarrow> (i1 = CHR ''+'' \<or> i2 = CHR ''+'' \<or> i1 = i2)" |
  "iface_name_eq (i1#i1s) (i2#i2s) \<longleftrightarrow> (i1 = CHR ''+'' \<and> i1s = [] \<or> i2 = CHR ''+'' \<and> i2s = []) \<or> (i1 = i2 \<and> iface_name_eq i1s i2s)" |
  "iface_name_eq _ _ \<longleftrightarrow> False"


  lemma "iface_name_eq ''lo'' ''lo''" by eval
  lemma "iface_name_eq ''lo'' ''lo+''" by eval
  lemma "iface_name_eq ''lo'' ''l+''" by eval
  lemma "iface_name_eq ''lo'' ''+''" by eval
  lemma "\<not> iface_name_eq ''lo'' ''lo++''" by eval
  lemma "\<not> iface_name_eq ''lo'' ''lo+++''" by eval
  lemma "\<not> iface_name_eq ''lo'' ''lo1+''" by eval
  lemma "\<not> iface_name_eq ''lo'' ''lo1''" by eval
  text{*The wildcard interface name*}
  lemma "iface_name_eq '''' ''+''" by eval

fun iface_name_is_wildcard :: "string \<Rightarrow> bool" where
  "iface_name_is_wildcard [] \<longleftrightarrow> False" |
  "iface_name_is_wildcard [s] \<longleftrightarrow> s = CHR ''+''" |
  "iface_name_is_wildcard (_#ss) \<longleftrightarrow> iface_name_is_wildcard ss"
lemma iface_name_is_wildcard_alt: "iface_name_is_wildcard eth \<longleftrightarrow> eth \<noteq> [] \<and> hd (rev eth) = CHR ''+''"
  apply(induction eth rule: iface_name_is_wildcard.induct)
   apply(simp_all)
  apply(rename_tac s s' ss)
  apply(case_tac "rev ss")
   apply(simp_all)
  done
(*lemma iface_name_is_wildcard_cases: "iface_name_is_wildcard eth \<longleftrightarrow> (case rev eth of [] \<Rightarrow> False | s#ss \<Rightarrow> s = CHR ''+'')"
  apply(induction eth rule: iface_name_is_wildcard.induct)
   apply(simp_all)
  apply(rename_tac s s' ss)
  apply(case_tac "rev ss")
   apply(simp_all)
  done*)

definition iface_name_prefix :: "string \<Rightarrow> string" where
  "iface_name_prefix i \<equiv> (if iface_name_is_wildcard i then butlast i else i)"
lemma "iface_name_prefix ''eth4'' = ''eth4''" by eval
lemma "iface_name_prefix ''eth+'' = ''eth''" by eval
lemma "iface_name_prefix ''eth++'' = ''eth+''" by eval --"the trailing plus is a constant and not a wildcard!"
lemma "iface_name_prefix '''' = ''''" by eval

lemma "take (length i - 1) i = butlast i" by (metis butlast_conv_take) 

lemma iface_name_eq_alt: "iface_name_eq i1 i2 \<longleftrightarrow> i1 = i2 \<or>
      iface_name_is_wildcard i1 \<and> take ((length i1) - 1) i1 = take ((length i1) - 1) i2 \<or>
      iface_name_is_wildcard i2 \<and> take ((length i2) - 1) i2 = take ((length i2) - 1) i1"
apply(induction i1 i2 rule: iface_name_eq.induct)
       apply(simp_all)
  apply(simp_all add: iface_name_is_wildcard_alt take_Cons' split:split_if_asm)
        apply(safe)
done

lemma iface_name_eq_refl: "iface_name_eq is is" by(simp add: iface_name_eq_alt)
lemma iface_name_eq_sym: "iface_name_eq i1 i2 \<Longrightarrow> iface_name_eq i2 i1" by(auto simp add: iface_name_eq_alt)
lemma iface_name_eq_not_trans: "\<lbrakk>i1 = ''eth0''; i2 = ''eth+''; i3 = ''eth1''\<rbrakk> \<Longrightarrow> 
    iface_name_eq i1 i2 \<Longrightarrow> iface_name_eq i2 i3 \<Longrightarrow> \<not> iface_name_eq i1 i3" by(simp)

lemma "iface_name_eq (i2 # i2s) [] \<Longrightarrow> i2 = CHR ''+'' \<and> i2s = []" by(auto simp add: iface_name_eq_alt)



text{*Examples*}
  lemma "iface_name_eq ''eth+'' ''eth3''" by eval
  lemma "iface_name_eq ''eth+'' ''e+''" by eval
  lemma "iface_name_eq ''eth+'' ''eth_tun_foobar''" by eval
  lemma "iface_name_eq ''eth+'' ''eth_tun+++''" by eval
  lemma "\<not> iface_name_eq ''eth+'' ''wlan+''" by eval
  lemma "iface_name_eq ''eth1'' ''eth1''" by eval
  lemma "\<not> iface_name_eq ''eth1'' ''eth2''" by eval
  lemma "iface_name_eq ''eth+'' ''eth''" by eval
  lemma "\<not> iface_name_eq ''a'' ''b+''" by eval
  lemma "iface_name_eq ''+'' ''''" by eval
  lemma "iface_name_eq ''++++'' ''++''" by eval
  lemma "\<not> iface_name_eq '''' ''++''" by eval
  lemma "iface_name_eq ''+'' ''++''" by eval
  lemma "\<not> iface_name_eq ''ethA+'' ''ethB+''" by eval

  text{*If the interfaces don't end in a wildcard, then @{const iface_name_eq} is just simple equality*}
  lemma iface_name_eq_case_nowildcard: "\<lbrakk>\<not> iface_name_is_wildcard i1; \<not> iface_name_is_wildcard i2 \<rbrakk> \<Longrightarrow> iface_name_eq i1 i2 \<longleftrightarrow> i1 = i2"
    apply(simp add: iface_name_is_wildcard_alt iface_name_eq_alt)
    by blast
  text{*If there is exactly one wildcard, both interface strings are equal for the length of the wildcard minus one (called @{const iface_name_prefix}}*}
  lemma iface_name_eq_case_onewildcard: "\<lbrakk>iface_name_is_wildcard i1; \<not> iface_name_is_wildcard i2 \<rbrakk> \<Longrightarrow> iface_name_eq i1 i2 \<longleftrightarrow> 
      iface_name_prefix i1 = take (length (iface_name_prefix i1)) i2"
    apply(simp add: iface_name_eq_alt iface_name_prefix_def butlast_conv_take)
  by (metis diff_le_self min.commute min_def)

  text{*If both are wildcards, then they are equal in their wildcard prefix*}
  lemma iface_name_eq_case_twowildcard: "\<lbrakk>iface_name_is_wildcard i1; iface_name_is_wildcard i2 \<rbrakk> \<Longrightarrow> iface_name_eq i1 i2 \<longleftrightarrow> 
    take (min (length (iface_name_prefix i1)) (length (iface_name_prefix i2))) i1 = take (min (length (iface_name_prefix i1)) (length (iface_name_prefix i2))) i2"
    apply(simp add: iface_name_eq_alt iface_name_prefix_def)
    apply(safe)
      apply (metis min.commute take_take)
     apply (metis take_take)
    by (metis min_def)
  
    text{*If both are wildcards of equal length, then both iface names are actually equal*}
    lemma iface_name_eq_case_twowildcardeqlength: 
      assumes "length i1 = length i2" and "iface_name_is_wildcard i1" and "iface_name_is_wildcard i2"
      shows "iface_name_eq i1 i2 \<longleftrightarrow> i1 = i2"
    proof -
      {
          fix n have "(min n (n - Suc 0)) = (n - Suc 0)" by linarith
      } note min_help=this
      from assms have i1_last: "last i1  = CHR ''+''" and i2_last: "last i2  = CHR ''+''"
        apply(simp_all add: iface_name_is_wildcard_alt)
        by (metis hd_rev)+
      from assms have "i1 \<noteq> []" and "i2 \<noteq> []"
        by(simp_all add: iface_name_is_wildcard_alt)

      from iface_name_eq_case_twowildcard assms have "iface_name_eq i1 i2 \<longleftrightarrow>
            take (min (length (iface_name_prefix i1)) (length (iface_name_prefix i2))) i1 = 
            take (min (length (iface_name_prefix i1)) (length (iface_name_prefix i2))) i2" by simp
      also have "\<dots> \<longleftrightarrow> take (length i1 - 1) i1 = take (length i1 - 1) i2"
        by(simp add: assms iface_name_prefix_def min_help)
      also have "\<dots> \<longleftrightarrow> butlast i1 = butlast i2" using assms(1) butlast_conv_take by metis
      also have "\<dots> \<longleftrightarrow> butlast i1 @ [last i1] = butlast i2 @ [last i2]"
        using i1_last i2_last by simp
      finally show "iface_name_eq i1 i2 \<longleftrightarrow> i1 = i2" using `i1 \<noteq> []` `i2 \<noteq> []` append_butlast_last_id by simp
    qed
      
      

  
  (*fun iface_name_leq :: "string \<Rightarrow> string \<Rightarrow> bool" where
    "iface_name_leq [] [] \<longleftrightarrow> True" |
    "iface_name_leq [i1] [] \<longleftrightarrow> False" |
    "iface_name_leq [] [i2] \<longleftrightarrow> (i2 = CHR ''+'')" |
    "iface_name_leq [i1] [i2] \<longleftrightarrow> (i1 = i2 \<or> i2 = CHR ''+'')" |
    "iface_name_leq (i1#i1s) (i2#i2s) \<longleftrightarrow> (i2 = CHR ''+'' \<and> i2s = []) \<or> (i1 = i2 \<and> iface_name_leq i1s i2s)" |
    "iface_name_leq _ _ \<longleftrightarrow> False"


  lemma "iface_name_leq ''lo'' ''lo''" by eval
  lemma "iface_name_leq ''lo'' ''lo+''" by eval
  lemma "iface_name_leq ''lo'' ''l+''" by eval
  lemma "iface_name_leq ''lo'' ''+''" by eval
  lemma "\<not> iface_name_leq ''lo+'' ''lo''" by eval
  lemma "\<not> iface_name_leq ''l+'' ''lo''" by eval
  lemma "\<not> iface_name_leq ''+'' ''lo''" by eval
  lemma "\<not> iface_name_leq ''lo'' ''lo++''" by eval
  lemma "iface_name_leq '''' ''+''" by eval
  lemma "iface_name_leq ''++'' ''+''" by eval
  lemma "iface_name_leq ''+'' ''++''" by eval (*NOOO*)
  lemma "\<not> iface_name_leq ''+'' ''''" by eval


  lemma "iface_name_leq i1 i2 \<longleftrightarrow> iface_name_eq i1 i2 \<and> (length (iface_name_prefix i2) \<le> length (iface_name_prefix i1))"
  apply(induction i1 i2 rule: iface_name_leq.induct)
         apply(simp_all)
         nitpick
    apply(simp_all add: iface_name_is_wildcard_alt take_Cons' split:split_if_asm)
          apply(safe)
  done
  lemma iface_name_leq_alt: "iface_name_leq i1 i2 \<longleftrightarrow> i1 = i2 \<or>
        iface_name_is_wildcard i2 \<and> take ((length i2) - 1) i2 = take ((length i2) - 1) i1"
  apply(induction i1 i2 rule: iface_name_leq.induct)
         apply(simp_all)
    apply(simp_all add: iface_name_is_wildcard_alt take_Cons' split:split_if_asm)
          apply(safe)
  done
  lemma iface_name_leq_iff_eq: "iface_name_leq i1 i2 \<longleftrightarrow> iface_name_eq i1 i2 \<and> (
            i1 = i2 \<or> 
            iface_name_is_wildcard i2 \<and> \<not> iface_name_is_wildcard i1 \<or>
            iface_name_is_wildcard i1 \<and> iface_name_is_wildcard i2 \<and> take ((length i2) - 1) i2 = take ((length i2) - 1) i1)"
    apply(induction i1 i2 rule: iface_name_leq.induct)
           apply(simp_all)
      apply(simp_all add: take_Cons' iface_name_eq_alt iface_name_is_wildcard_alt)
      apply(safe)
      apply(simp_all) (*TODO: indent by 117*)
    done


  lemma iface_name_leq_refl: "iface_name_leq is is" by(simp add: iface_name_leq_alt iface_name_eq_refl)
  lemma iface_name_leq_sym: "iface_name_leq i1 i2 \<Longrightarrow> iface_name_leq i2 i1 \<Longrightarrow> i1 = i2"
    nitpick
    apply(simp add: iface_name_leq_alt iface_name_eq_alt)
    oops
  lemma iface_name_leq_not_trans: "\<lbrakk>i1 = ''eth0''; i2 = ''eth+''; i3 = ''eth++''\<rbrakk> \<Longrightarrow> 
    iface_name_leq i1 i2 \<Longrightarrow> iface_name_leq i2 i3 \<Longrightarrow> \<not> iface_name_leq i1 i3" by(simp)

  lemma "iface_name_leq i1 i2 \<Longrightarrow> (*iface_name_leq i2 i1 \<Longrightarrow>*) iface_name_eq i1 i2" by(simp add: iface_name_leq_iff_eq iface_name_eq_sym)
  lemma "iface_name_leq i2 i1 \<Longrightarrow> (*iface_name_leq i2 i1 \<Longrightarrow>*) iface_name_eq i1 i2" by(simp add: iface_name_leq_iff_eq iface_name_eq_sym)*)


  text{*takes two interface names, returns the most specific one*}
  definition iface_name_conjuct_merge :: "string \<Rightarrow> string \<Rightarrow> string option" where
    "iface_name_conjuct_merge i1 i2 \<equiv> (if \<not> iface_name_eq i1 i2 then None else
      if iface_name_is_wildcard i1 \<and> iface_name_is_wildcard i2 then 
        (if length i1 \<le> length i2 then Some i2 else Some i1)
      else if iface_name_is_wildcard i1 then Some i2
      else Some i1
      )"


  lemma iface_name_conjuct_merge_sym: "iface_name_conjuct_merge i1 i2 = iface_name_conjuct_merge i2 i1"
    apply(simp add: iface_name_conjuct_merge_def)
    apply(safe)
                 apply(simp_all add: iface_name_eq_sym)
      apply(simp_all add: iface_name_eq_case_nowildcard)
    apply(simp add: iface_name_eq_case_twowildcardeqlength)
    done

  lemma "iface_name_conjuct_merge ''lo'' ''lo'' = Some ''lo''" by eval
  lemma "iface_name_conjuct_merge ''lo'' ''lo+'' = Some ''lo''" by eval
  lemma "iface_name_conjuct_merge ''lo'' ''l+'' = Some ''lo''" by eval
  lemma "iface_name_conjuct_merge ''lo'' ''+'' = Some ''lo''" by eval
  lemma "iface_name_conjuct_merge ''lo'' ''lo++'' = None" by eval
  lemma "iface_name_conjuct_merge '''' ''+'' = Some ''''" by eval
  lemma "iface_name_conjuct_merge ''++'' ''+'' = Some ''++''" by eval
  lemma "iface_name_conjuct_merge ''x'' '''' = None" by eval


   lemma "{i. \<exists> X. (iface_name_conjuct_merge i1 i2) = Some X \<and> iface_name_eq X i} = {i. iface_name_eq i1 i} \<inter> {i. iface_name_eq i2 i}"
    nitpick (*more iface_name_eq on right hand side?*)
    oops

   lemma "iface_name_eq i1 i \<and> iface_name_eq i2 i \<longleftrightarrow> (case (iface_name_conjuct_merge i1 i2) of 
      Some X \<Rightarrow> iface_name_eq X i |
      None \<Rightarrow> False)"
      oops




(*eth+ and !eth42. Problem!*)
fun match_iface_name_and :: "string negation_type \<Rightarrow> string negation_type \<Rightarrow> string negation_type option" where
  "match_iface_name_and (Pos i1) (Pos i2) = (if iface_name_eq i1 i2 then (if length i1 \<ge> length i2 then Some (Pos i1) else Some (Pos i2)) else None)"
  (*we need the 'shorter' iface. probably we want a pseudo order on the ifaces*)
    (*An order which is not transitive?*)


hide_const (open) internal_iface_name_match

end
