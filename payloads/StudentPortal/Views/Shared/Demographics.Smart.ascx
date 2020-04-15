<%@ Control Language="VB" Inherits="System.Web.Mvc.ViewUserControl(Of StudentPortal.DemographicsFormView)" %>
<%@ Import Namespace="StudentPortalShell.Helpers" %>
<%@ Import Namespace="StudentPortalData" %>
<table class="mobiletable">
    <%If (Model.Demographics.Count > 0) Then%>
	    <tr>
		    <td colspan="2" width="100px">
                <div id="Demo_StuPhoto"></div>
            </td>
        </tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("name", "Name", Model.LabelList)%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).name%></td> 
		</tr>
        <tr>
            <td style="text-align:right;"><b><%=Html.AELabelFor("ident", "Local ID", Model.LabelList,"studemo.ident")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).ident%></td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("nickname", "Nickname", Model.LabelList,"studemo.nickname")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).nickname%></td>
		</tr>
        <tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("stateid", "State ID", Model.LabelList,"studemo.stateid")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).stateid%><br /></td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("birthdate", "Birthdate", Model.LabelList,"studemo.birthdate")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).birthdate%> </td>
		</tr>
        <tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("schname", "School", Model.LabelList,"school.schname")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).schname%></td>
		</tr>   
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("age", "Age", Model.LabelList)%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).age%> </td>
		</tr>
	<%If Not Model.HideGender Then%>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("gender", "Gender", Model.LabelList,"studemo.genderc")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).gender%></td>
		</tr>
	<%End If%>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("counselor", "Counselor", Model.LabelList,"studemo.counsfuniq")%>:</b></td>
            <td style="vertical-align:bottom;">
            <%If Model.Email And Model.Demographics(0).counsEmail.ToString.Trim > "" Then%>
                <a href="mailto:<%=Model.Demographics(0).counsEmail%>" title="Send Email">
                    <%=Model.Demographics(0).counselor%>
                </a>
            <%Else%>
                <%=Model.Demographics(0).counselor%>
            <%End If%>
			</td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("birthplace", "Birth Place", Model.LabelList,"studemo.birthplace")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).birthplace%></td>
		</tr>
	<%If Not Model.HideCitizenship Then%>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("CitizenStatus", "Citizenship", Model.LabelList,"studemo.citizenc")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).CitizenStatus%></td>
		</tr>
	<%End If%>
		<tr>
			<td style="text-align:right; white-space:pre-wrap;"><b><%=Html.AELabelFor("BirthVerifDoc", "Birth Verification", Model.LabelList, "studemo.bverbasc")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).BirthVerifDoc%></td>
		</tr>
	<%If Not Model.HideCitizenship Then%>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("Country", "Country", Model.LabelList,"studemo.countryc")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).Country%></td>
		</tr>
	<%End If%>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("BirthVerifDocNum", "Verification Document #", Model.LabelList, "studemo.bverdocnum")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).BirthDocNum%></td>
		</tr>
        <tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("MaritalStatus", "Marital Status", Model.LabelList,"studemo.maritalc")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).MaritalStatus%></td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("MigrantNum", "Migrant Number", Model.LabelList,"studemo.migrantnum")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).migrantnum%></td>
		</tr>
	<%If Model.SSN Then%>  
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("SSN", "SSN", Model.LabelList,"studemo.ssn")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).ssn%><br /></td>
		</tr>
	<%End If%>					
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("hispaniclatino", "Hispanic/Latino", Model.LabelList)%>:</b></td>
 			<td style="vertical-align:bottom;"><%=Model.Demographics(0).hispaniclatino%></td>
		</tr>
		<tr>
			<td style="text-align:right;vertical-align:top;"><b><%=Html.AELabelFor("ethnicity", "Race", Model.LabelList,"studemo.ethnicc")%>:</b></td>
 			<td  style="vertical-align:bottom;">
            <%If Model.Demographics(0).hispaniclatino <> "Yes" Then%>
				<%=Model.Demographics(0).ethnicity%><br />
            <%End If%>
            <%If Model.Ethnics.Count() > 0 Then%>
    			<table>
                <%For Each oethnic In Model.Ethnics%>
					<tr>
						<td>
							<%=oethnic.descript %>
                            <%If oethnic.pct <> "" And oethnic.pct <> "0" Then%>
								<%=" (" & oethnic.pct & "%)" %>
                            <%End If%>
						</td>
					</tr>
                <%Next%>
				</table>
            <%End If%>
			</td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("englishProf", "English Proficiency", Model.LabelList)%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).englishProf%></td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("primaryLanguage", "Primary Language", Model.LabelList,"studemo.primlangc")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).primaryLanguage%></td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("homeLanguage", "Home Language", Model.LabelList,"studemo.homelangc")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).homeLanguage%></td>
		</tr>
		<tr>
			<td style="text-align:right;vertical-align:top;"><b><%=Html.AELabelFor("homeaddrline1", "Home Address", Model.LabelList,"studemo.homeaddr1")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).homeaddrline1%><br /><%=Model.Demographics(0).homeaddrline2%></td>
		</tr>
		<tr>
			<td style="text-align:right;vertical-align:top;"><b><%=Html.AELabelFor("mailaddrline1", "Mailing Address", Model.LabelList,"studemo.mailaddr1")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).mailaddrline1%><br /><%=Model.Demographics(0).mailaddrline2%></td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("addrverif", "Address Verified", Model.LabelList,"studemo.addrverif")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).addrverif%></td>
		</tr>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("primaryphone", "Primary Phone", Model.LabelList, "studemo.phnnumber")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).homephone%></td>
		</tr>
        <%If Model.StuPhones.Count > 0 Then%>
    		<tr>
	    		<td style="text-align:right;"><b><%=Html.AELabelFor("additionalphones", "Additional Phones", Model.LabelList,"stuphone.phnnumber")%>:</b></td>
				<td style="vertical-align:bottom;">
                    <%For Each orow In Model.StuPhones%>
        		        <%=orow.PhoneNumber%><br />
                    <%Next%>
        		</td>
			</tr>
        <%End If%>
		<tr>
			<td style="text-align:right;"><b><%=Html.AELabelFor("emailaddr", "Email", Model.LabelList,"studemo.emailaddr")%>:</b></td>
			<td style="vertical-align:bottom;"><%=Model.Demographics(0).emailaddr%></td>
		</tr>
        <%If Model.SchoolEmail <> "" Then%>
			<tr>
				<td>&nbsp;</td>
				<td>
					<a id="DemographicSchoolEmail" href="mailto:<%=Model.SchoolEmail%>?subject=Demographic information inquiry for: <%=SPSession.StudentName%>&amp;body=Submitted by: <%=SPSession.FirstName & " " & SPSession.LastName%>"><%=Html.AELabelFor("DemographicSchoolEmail","Email School Personnel to Inquire About Demographic Information",Model.LabelList) %></a>
				</td>
			</tr>
        <%End If%>
    <%Else%>
	    <tr>
            <td colspan="2"style="text-align:center;"> No Data Available</td>
	    </tr>
    <%End If%>    
</table>
<script type="text/javascript">
	$('#Demo_StuPhoto').empty();
	AjaxLoad($('#Demo_StuPhoto'), '<%=Url.Action("LoadImageDiv","Home") %>');
</script>
