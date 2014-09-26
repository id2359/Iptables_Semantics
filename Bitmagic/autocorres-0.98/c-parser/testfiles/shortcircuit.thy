(*
 * Copyright (C) 2014 NICTA
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions, and the following disclaimer,
 *    without modification.
 *
 * 2. Redistributions in binary form must reproduce at minimum a disclaimer
 *    substantially similar to the "NO WARRANTY" disclaimer below
 *    ("Disclaimer") and any redistribution must be conditioned upon
 *    including a substantially similar Disclaimer requirement for further
 *    binary redistribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDERS OR CONTRIBUTORS BE LIABLE FOR SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGES.
 *)

theory shortcircuit
imports "../CTranslation"
begin

lemma word32_sint_1[simp]:
 "sint (1::32 word) = 1"
 apply(subst word_1_no)
 apply(subst sint_numeral)
 apply(simp)
done

install_C_file "shortcircuit.c"


context shortcircuit
begin

  thm f_body_def
  thm deref_body_def
  thm test_deref_body_def
  thm imm_deref_body_def
  thm simple_body_def
  thm condexp_body_def

lemma semm: "\<Gamma> \<turnstile> \<lbrace> \<acute>p = NULL \<rbrace> Call test_deref_'proc \<lbrace> \<acute>ret__int = 0 \<rbrace>"
apply vcg
apply simp
done

lemma condexp_semm:
  "\<Gamma> \<turnstile> \<lbrace> \<acute>i = 10 & \<acute>ptr = NULL & \<acute>ptr2 = NULL \<rbrace>
                    Call condexp_'proc
                  \<lbrace> \<acute>ret__int = 23 \<rbrace>"
apply vcg
apply (simp add: word_sless_def word_sle_def)
done

end (* context *)

end (* theory *)