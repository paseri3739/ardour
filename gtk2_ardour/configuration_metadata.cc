
/* This file was generated by tools/process-metadata. DO NOT EDIT THIS FILE. EVER! */
void
UIConfiguration::build_metadata ()
{

#define VAR_META(name,...)  { char const * _x[] { __VA_ARGS__ }; all_metadata.insert (std::make_pair<std::string,Metadata> ((name), PBD::upcase (_x))); }

	VAR_META (X_("font-scale"), _("fonts"), _("font"), _("size"), _("scaling"), _("readable"), _("readability"),  NULL);

}
