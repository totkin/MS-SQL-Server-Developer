using System;
using System.Collections;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;

using Microsoft.SqlServer.Server;

public partial class UserDefinedFunctions
{
    private class EmailResult
    {
        public SqlInt32 PersonId;
        public SqlString EmailAdress;

        public EmailResult(SqlInt32 PersonId, SqlString emailAdress)
        {
            PersonId = PersonId;
            EmailAdress = emailAdress;
        }
    }

    public static bool ValidateEmail(SqlString emailAddress)
    {
        if (emailAddress.IsNull)
            return false;

        if (!emailAddress.Value.EndsWith("@wideworldimporters.com"))
            return false;

        // Validate the address. Put any more rules here.  
        return true;
    }

    [SqlFunction(
        DataAccess = DataAccessKind.Read,
        FillRowMethodName = "FindInvalidEmails_FillRow",
        TableDefinition = "PersonId int, EmailAddress nvarchar(256)")]
    public static IEnumerable FindInvalidEmails(SqlDateTime ValidFrom)
    {
        ArrayList resultCollection = new ArrayList();

        using (SqlConnection connection = new SqlConnection("context connection=true"))
        {
            connection.Open();

            using (SqlCommand selectEmails = new SqlCommand(
                "SELECT " +
                "[PersonID] ,[EmailAddress] " +
                "FROM [WideWorldImporters].[Application].[People] " +
                "WHERE [ValidFrom] >= @ValidFrom",
                connection))
            {
                SqlParameter ValidFromParam = selectEmails.Parameters.Add(
                    "@ValidFrom",
                    SqlDbType.DateTime);
                ValidFromParam.Value = ValidFrom;

                using (SqlDataReader emailsReader = selectEmails.ExecuteReader())
                {
                    while (emailsReader.Read())
                    {
                        SqlString emailAddress = emailsReader.GetSqlString(1);
                        if (ValidateEmail(emailAddress))
                        {
                            resultCollection.Add(new EmailResult(
                                emailsReader.GetSqlInt32(0),
                                emailAddress));
                        }
                    }
                }
            }
        }

        return resultCollection;
    }

    public static void FindInvalidEmails_FillRow(
        object emailResultObj,
        out SqlInt32 PersonId,
        out SqlString emailAdress)
    {
        EmailResult emailResult = (EmailResult)emailResultObj;

        PersonId = emailResult.PersonId;
        emailAdress = emailResult.EmailAdress;
    }
};